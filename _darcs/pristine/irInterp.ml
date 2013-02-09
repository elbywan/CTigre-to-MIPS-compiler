(*
Copyright (c) 2004-2005 by Juliusz Chroboczek and Roberto DiCosmo
Copyright (c) 2009 by Grégoire Henry

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*)

(** IrInterp : Interpretor for Intermediate Representation *)

open Ir
open Printf

(** Concrete sizes associated with a frame (in bytes) *)

let wordsize = 4 (** All platform we consider are 32-bits *)
let wordshift = 2 (** wordsize = 2^wordshift *)

(** Trace functions *)

let trace_indent_level = ref 0;;
let time = ref 0
let time_flag = ref false

let trace_indent () = incr trace_indent_level;;
let trace_unindent () = decr trace_indent_level;;

let trace_prefix () =
 (if !time_flag then sprintf "%5d " !time else "")^
 (String.make (!trace_indent_level) ' ');;

let fake_prefix () =
 String.make (6 + !trace_indent_level) ' ';;

let trace_flag = ref true

let trace s =
  if !trace_flag then printf "%s %s\n" (trace_prefix()) s

let trace_notime s =
  if !trace_flag then printf "%s %s\n" (fake_prefix()) s

let raw_trace s =
  if !trace_flag then printf "%s\n" s

let tracei s1 i =
  if !trace_flag then printf "%s %s %d\n" (trace_prefix ()) s1 i

let traceil_notime s1 l =
  if !trace_flag
  then
    begin
      printf "%s %s " (fake_prefix ()) s1;
      List.iter (fun n -> print_int n; print_string " ") l;
      print_string "\n"
    end

let trace_ahash h =
  if !trace_flag then Hashtbl.iter (fun k _ -> trace k) h

let trace_ahash_i h =
  if !trace_flag then Hashtbl.iter (fun k d -> tracei k d) h

let pr_temp () = Temp.string_of_temp

(** Misc utilities *)

let charlist_to_string cl =
  let n = List.length cl in
  let s = String.create n in
  for i = 0 to n-1 do
    s.[i] <- List.nth cl i
  done;
  s

(** A module for extensible arrays. In addition, these arrays are
    protected from read-before-write, and they have a string name
    attached to them for error message *)

module ExtArray = struct

 type t = { mutable array: int option array; name: string; }

 let make name = { array=Array.make 0 None; name=name }

 let reset a = (a.array <- Array.make 0 None)

 let get a n =
   try
     if n >= Array.length a.array then raise Not_found;
     match a.array.(n) with
       | Some i -> i
       | None -> raise Not_found
   with Not_found ->
     failwith ("Read before write at "^(string_of_int n))

 let set a n m =
   if n >= Array.length a.array
   then begin
     let newa = Array.make (n + 1) None in
     Array.blit a.array 0 newa 0 (Array.length a.array);
     a.array <- newa
   end;
   a.array.(n) <- Some m

 let length a = Array.length a.array

end

type ('stms, 'exp) state = {
    labels: (Label.lbl, 'stms) Hashtbl.t;
    data: string array; (* TODO strings in heap *)
    strings_addr: (Label.lbl, int) Hashtbl.t;
    heap: ExtArray.t;
    mutable current_malloc: int;
    cstack: ExtArray.t;
      (* concrete stack, used by ir code *)
    mutable astack: (Temp.temp, int) Hashtbl.t list;
      (* abstract stack used by interpretor when keepings temps *)
    mutable sp: int;
    mutable fp: int;
    funs: 'exp proc_desc list;
    mutable ra: int;
  }

let find_function st lbl =
  List.find (fun f -> f.entry = lbl) st.funs

(** Heap access *)

let setmem st n =
  if n mod 4 <> 0 then failwith ("Unaligned write: "^string_of_int n);
  if n < 0 then
    ExtArray.set st.cstack (-n/4)
  else
    ExtArray.set st.heap (n/4)

let getmem st n =
  if n mod 4 <> 0 then failwith ("Unaligned read"^string_of_int n);
  if n < 0 then
    ExtArray.get st.cstack (-n/4)
  else
    ExtArray.get st.heap (n/4)

let malloc st n =
  let next_align2 = 4*((n+3)/4) in
  let a = st.current_malloc in
  st.current_malloc <- st.current_malloc + next_align2;
  a

(** Labels initialisation *)

let err_jump c l =
  ignore (Format.flush_str_formatter ());
  Format.fprintf Format.str_formatter
    "Unsupported case: %s JUMP to label %a which is in a different ESEQ level"
    c Label.pr_label l;
  Format.flush_str_formatter ()

let collect_labels prog =
  let lbls = Hashtbl.create 41 in
  let add = Hashtbl.add lbls in
  let rec collect_stm all after = function
    | LABEL l -> add l after
    | JUMP l -> if not (List.mem (LABEL l) all) then failwith (err_jump "" l)
    | CJUMP (_, e1, e2, l1, l2) ->
	if not (List.mem (LABEL l1) all) then failwith (err_jump "C" l1);
	if not (List.mem (LABEL l2) all) then failwith (err_jump "C" l2);
	collect_exp e1; collect_exp e2
    | MOVE (e1, e2) -> collect_exp e1; collect_exp e2
    | EXP e -> collect_exp e
  and collect_exp = function
    | BINOP (_, e1, e2) -> collect_exp e1; collect_exp e2
    | WORDMUL (e) -> collect_exp e
    | MEM e -> collect_exp e
    | ESEQ (s, e) -> collect_stms s s; collect_exp e
    | CALL (_, ee) -> List.iter collect_exp ee
    | FP | TEMP _ | CONST _ | STR _ -> ()
  and collect_stms all after = match after with
    | [] -> ()
    | a::l -> collect_stm all l a; collect_stms all l
  in
  List.iter (fun proc -> collect_exp proc.code) prog.procs;
  if !trace_flag then begin
    trace "## Labels:";
    Hashtbl.iter (fun k _ -> trace (Label.string_of_label k)) lbls;
    trace "";
  end;
  lbls

(** Strings initialisation *)

let collect_strings prog =
  let strings_addr = Hashtbl.create 41 in
  let strings = Array.of_list prog.strings in
  trace "## Strings:";
  Array.iteri (fun i (lbl, s) ->
    Hashtbl.add strings_addr lbl (-i-1);
    trace (Printf.sprintf "%s @(%i): %S" (Label.string_of_label lbl) (-i-1) s)) strings;
  trace "";
  Array.map snd strings, strings_addr

(** String and Char access *)

let find_string_addr state l = Hashtbl.find state.strings_addr l

let getbyte st n =
  let m = n / 4 and s = (n mod 4) * 8 in
  ((ExtArray.get st.heap m) lsr s) land 255

let setbyte st n b =
  let m = n / 4 and s = (n mod 4) * 8 in
  if m >= ExtArray.length st.heap then ExtArray.set st.heap m 0;
  ExtArray.set st.heap m
    ((ExtArray.get st.heap m) land (lnot (255 lsl s)) lor (b lsl s))

let getchar st n = Char.chr (getbyte st n)

let setchar st n c = setbyte st n (Char.code c)

let make_string st s =
  let l = String.length s in
  let n = malloc st ((String.length s) + 1) in
  for i = 0 to l - 1 do
    setchar st (n + i) (String.get s i)
  done;
  setchar st (n + l) '\000';
  n

let rec deref_string st n =
  if getchar st n = '\000'
  then []
  else (getchar st n) :: deref_string st (n + 1)

let find_string st n =
  if n < 0 then
    st.data.(-n-1)
  else
    charlist_to_string (deref_string st n)

(** Temp and special registers are stored on a abstract stack,
    that is a list of (abstract) frame *)

let gettemp state t =
  Hashtbl.find (List.hd state.astack) t

let settemp state t v =
  Hashtbl.add (List.hd state.astack) t v

(** Initial state *)

let make_initial_state prog =
  let data, strings_addr = collect_strings prog in
  {
    labels = collect_labels prog;
    data = data;
    strings_addr = strings_addr;

    heap = ExtArray.make "heap";
    current_malloc = 4;

    cstack = ExtArray.make "stack";
    sp = -4000;

    astack = [Hashtbl.create 41];
    fp = -4000;

    funs = prog.procs;
    ra = 0;
  }

(** *)

type leftvalue = ADDR of int | REG of Temp.temp

(** Main interpretation loop *)

exception TheEnd

let interp_prim state f args = match Label.string_of_label f, args with
  | "printint", [n] ->
      raw_trace ">>>Integer output: ";
      print_int n;
      raw_trace "\n<<<";
      0
  | "print", [s] ->
      raw_trace ">>>String output: ";
      printf "%s" (find_string state s);
      flush stdout;
      raw_trace "\n<<<";
      0
  | "readint", [] ->
      raw_trace ">>>Read integer: ";
      read_int()
  | "getchar", [] ->
      flush stdout;
      Char.code (input_char stdin)
  | "getstring", [n] ->
      raw_trace (">>>Read string ("^(string_of_int n)^" bytes)");
      let s = String.make n ' ' in
      for i = 0 to n-1 do s.[i] <- input_char stdin done;
      make_string state s
  | "malloc", [n] ->
      malloc state n
  | "mkstring", [c] ->
      make_string state (String.make 1 (Char.chr c))
  | "concat", [a;b] ->
      let s1 = find_string state a
      and s2 = find_string state b
      in make_string state (s1 ^ s2)
  | "size", [a] -> String.length (find_string state a)
  | "chr", [x] -> x
  | "ord", [x] -> x
  | "exit", _ ->
      raw_trace ">>>Exit";
      raise TheEnd
  | _ ->
      failwith "Unknown primitive"

let rec interp_stms state stms =
  match stms with
  | [] -> ()
  | s::k -> interp_stm state k s

and interp_stm state k stm =
  incr time;
  match stm with
  | EXP e -> trace "EXP"; ignore (interp_exp state e); interp_stms state k
  | LABEL l -> trace ("LABEL "^Label.string_of_label l); interp_stms state k
  | JUMP l -> trace ("JUMP to " ^Label.string_of_label l); jump state l
  | CJUMP (r, e1, e2, l1, l2) ->
      let t = !time in
      trace ("[CJUMP "^(IrPrint.relopname r));
      trace_indent();
      let v1 = interp_exp state e1 in
      let v2 = interp_exp state e2 in
      trace_unindent();
      let l = if IrUtil.relop r v1 v2 then l1 else l2 in
      trace_notime (sprintf "]@%d CJUMP(%s,%d,%d,%s,%s) go to %s"
	      t (IrPrint.relopname r) v1 v2
		      (Label.string_of_label l1) (Label.string_of_label l2) (Label.string_of_label l));
      jump state l
  | MOVE (e1, e2) ->
      let t = !time in
      trace "[MOVE";
      trace_indent();
      let a = left_interp_exp state e1 in
      let b = interp_exp state e2 in
      trace_unindent();
      begin match a with
	| ADDR a ->
	    trace_notime (sprintf "]@%d MOVE addr(%d) <=== %d" t a b);
	    setmem state a b
	| REG temp ->
	    trace_notime (sprintf "]@%d MOVE temp %a <=== %d"
			    t pr_temp temp b);
	    settemp state temp b
      end;
      interp_stms state k

and jump state  l = interp_stms state (Hashtbl.find state.labels l)

and interp_exp state e = incr time; match e with
  | FP -> state.fp
  | BINOP (b, e1, e2) ->
      let t = !time in
      trace ("[BINOP "^(IrPrint.binopname b));
      trace_indent();
      let c = interp_exp state e1 in
      let d = interp_exp state e2 in
      trace_unindent();
      let r = IrUtil.binop b c d in
      trace_notime
	(sprintf "]@%d BINOP(%s,%d,%d) ===> %d" t (IrPrint.binopname b) c d r);
      r
  | WORDMUL e ->
      let t = !time in
      trace "[WORDMUL ";
      trace_indent();
      let c = interp_exp state e in
      trace_unindent();
      let r = c lsl wordshift in
      trace_notime (sprintf "]@%d WORDMUL(%d) ===> %d" t c r); r
  | MEM e ->
      let t = !time in
      trace "[MEM";
      trace_indent();
      let a = interp_exp state e in
      let n = getmem state a in
      trace_unindent ();
      trace_notime (sprintf "]@%d MEM(%d) ===> %d" t a n); n
  | TEMP temp ->
      let n = gettemp state temp in
      trace (sprintf "TEMP %a ===> %d" pr_temp temp n); n
  | ESEQ (s, e) -> trace "ESEQ";
      interp_stms state s; interp_exp state e
  | STR l ->
      begin try
	let a = find_string_addr state l in
	trace (sprintf "STR %s ===> %d" (Label.string_of_label l) a); a
      with Not_found -> failwith ("Unknown string label "^Label.string_of_label l)
      end
  | CONST c -> trace (sprintf "CONST(%d) ===> %d" c c); c
  | CALL (fn, args) ->
      let t = !time in
      trace ("[CALL "^Label.string_of_label fn);
      trace_indent ();
      let a = List.map (interp_exp state) args in
      trace_unindent ();
      traceil_notime (sprintf "|@%d CALL %s : arg0, args =" t (Label.string_of_label fn)) a;
      trace_indent ();
      let res = try
	  let proc = find_function state fn in
	  interp_function state proc a
      with Not_found -> interp_prim state fn a in
      trace_unindent ();
      trace_notime (sprintf "]@%d CALL %s ===> %d" t (Label.string_of_label fn) res);
      res

and interp_function state proc args =
  let args = Array.of_list args in
  assert(proc.numargs = Array.length args);
  let oldfp = state.fp in
  (* Caller *)
  state.sp <- state.sp - proc.numargs * wordsize;
  Array.iteri (fun i a -> setmem state (state.sp+wordsize*i) a) args;
  (* Callee prologue *)
  state.sp <- state.sp - (proc.numvars+1) * wordsize;
  setmem state state.sp state.fp;
  state.astack <- Hashtbl.create 41 :: state.astack;
  state.fp <- state.sp + (proc.numvars+1) * wordsize;
  (* body *)
  let res = interp_exp state proc.code in
  (* Callee epilogue *)
  state.fp <- getmem state state.sp;
  state.astack <- List.tl state.astack;
  state.sp <- state.sp + (proc.numvars+1) * wordsize;
  (* Caller *)
  state.sp <- state.sp + proc.numargs * wordsize;
  assert (state.fp = oldfp);
  res

and left_interp_exp state e = match e with
  | MEM e -> ADDR (interp_exp state e)
  | TEMP t -> REG t
  | ESEQ (s, e) ->
      trace "ESEQ";
      interp_stms state s;
      left_interp_exp state e
  | (FP | STR _ | CONST _ | CALL _ | BINOP _ | WORDMUL _) as lval ->
      printf "Illegal left-handside of a MOVE:\n";
      IrPrint.print_exp lval;
      assert false

(** *)

let interp prog tracep =
  trace_indent_level := 0;
  time := 0;
  time_flag := false;
  trace_flag := tracep;
  let state = make_initial_state prog in
  setmem state (-4000) (-4000); (** fake StaticLink for allowing reading there later *)
  begin try
    ignore(interp_function state (find_function state Label.main) [])
  with TheEnd -> () end;
  print_newline ()
