(** Canon : functions for linearizing and canonizing I.R. code *)

open Ast
open Ir
open Lin

(** I) linearize *)

let rec commutable = function
  | LCONST _ | LSTR _ -> true
  | LBINOP (_,e1,e2) -> commutable e1 && commutable e2
  | LWORDMUL e -> commutable e
  | _ -> false

(** [get_exps_in_stm : Ir.stm -> Ir.exp list]
    This extracts some particular internal exps in a stm *)

let get_exps_in_stm = function
  | MOVE (TEMP _, CALL (_, el)) -> el
  | MOVE (TEMP _, b) -> [b]
  | MOVE (MEM e, b) -> [e; b]
  | MOVE (ESEQ _, _) -> failwith "Linearize: MOVE (ESEQ _, _) should be done in do_stm"
  | MOVE _ -> failwith "Linearize: illegal left-handside in a MOVE"
  | CJUMP (_, a, b, _, _) -> [a;b]
  | EXP (CALL (_, el)) -> el
  | EXP e -> [e]
  | LABEL _ | JUMP _ -> []

(** [rebuild_stm : Ir.stm -> Lin.exp list -> Lin.stm list]
    In a stm, replace some internal exps by updated ones.
    The patterns must correspond to the ones in get_exps_in_stm.
    For instance, we should have [(rebuild_stm s (get_exps_in_stm s)) = [s]] 

    The answer type is a list solely to handle the case of [EXP(e)] with
    [e] pure, that has no conterpart in linearized code.
*)

let rebuild_stm s el = match s,el with
  | MOVE (TEMP t, CALL (f,_)), _ -> [LMOVETEMPCALL (t,f,el)]
  | MOVE (TEMP t, _), [e1] -> [LMOVETEMP (t, e1)]
  | MOVE (MEM _, _), [e1;e2] -> [LMOVEMEM (e1, e2)]
  | CJUMP (r,_,_,l1,l2), [e1;e2] -> [LCJUMP (r,e1,e2,l1,l2)]
  | EXP (CALL (f,_)), _ -> [LEXPCALL (f,el)]
  | EXP _, [e1] -> []
  | LABEL l, [] -> [LLABEL l]
  | JUMP l, [] -> [LJUMP l]
  | _,_ -> failwith "Linearize: unexpected stm or exp list in rebuild_stm"

(** [get_exps_in_exp : Ir.exp -> Ir.exp list]
    This extracts some particular internal exps in an exp *)

let get_exps_in_exp = function
  | BINOP (_,e1,e2) -> [e1;e2]
  | MEM e -> [e]
  | WORDMUL e -> [e]
  | CALL _ as e -> [e]
  | FP | TEMP _ | CONST _ | STR _ -> []
  | ESEQ _ -> failwith "Linearize: ESEQ should be done in do_exp"

(** [rebuild_exp : Ir.exp -> Lin.exp list -> Lin.exp]
    In an exp, replace some internal exp by updated ones.
    The patterns must correspond to the ones in get_exps_in_exp.
    For instance, we should have [(rebuild_exp s (get_exps_in_exp s)) = s] *)

and rebuild_exp e el = match e,el with
  | BINOP (o,_,_), [e1;e2] -> LBINOP (o,e1,e2)
  | MEM _, [e1] -> LMEM e1
  | WORDMUL _, [e] -> LWORDMUL e
  | CALL _, [e] -> e
  | FP, [] -> LFP
  | TEMP t, [] -> LTEMP t
  | CONST n, [] -> LCONST n
  | STR l, [] -> LSTR l
  | _,_ -> failwith "Linearize: unexpected exp or exp list in rebuild_exp"


(** [do_exp : Ir.exp -> Lin.stms * Lin.exp]
   Internal statements are push to the external level and grouped in a stms *)

let rec do_exp = function
  | ESEQ (s, e) ->
      let stms = do_stms s
      and (stms', e) = do_exp e
      in (stms @ stms', e)
  | e ->
      let (stms,exps) = do_exps (get_exps_in_exp e) in
      (stms, rebuild_exp e exps)

(** [do_exps : Ir.exp list -> Lin.stms * Lin.exp list]
   This function iterates [do_exp] on its input list and accumulates
   generated stms. Some stms are commuted with some exp if possible
   otherwise new temps are added. Any lonely [CALL] is placed under a [MOVE].
*)

and do_exps = function
  | [] -> ([], [])
  | (CALL _ as e)::rest ->
      let t = Temp.new_temp()
      in do_exps (ESEQ([MOVE(TEMP t, e)], TEMP t) :: rest)
  | a::rest ->
      let (stms, e) = do_exp a
      and (stms', el) = do_exps rest in
      if commutable e || stms' = []
      then (stms @ stms', e::el)
      else
        let t = Temp.new_temp () in
        (stms @ [LMOVETEMP (t, e)] @ stms', LTEMP t :: el)

(** [do_stm : Ir.stm -> Lin.stms]
    Same idea as [do_exp], except that we obtain here a unique [stms list] *)

and do_stm = function
  | MOVE (ESEQ (s, e), b) -> do_stms s @ do_stm (MOVE (e, b))
  | s ->
      let (stms,exps) = do_exps (get_exps_in_stm s) in
      (stms @ rebuild_stm s exps)

(** [do_stms : Ir.stms -> Lin.stms]
   We iterate [do_stm] on each statement of the list, and concatenate the result *)

and do_stms l = List.flatten (List.map do_stm l)

let linearize = do_exp


(** II) basicBlocks *)

(** A basic block representation: 
   [{ label=l; inner=b; last=s}] is equivalent to 
   [([LABEL lab] @ b @ [s])]
*)

type basicBlock = { label : Label.lbl; inner : Lin.stms; last : Lin.stm }

(** Take list of statements and make basic blocks satisfying conditions
   3 and 4 above, in addition to the extra condition that
   every block ends with a [LJUMP] or [LCJUMP] *)

let basicBlocks stms =
  let donel = Label.new_label "done" in
  let add_block, flush_blocks =
    let l = ref [] in
    (fun e -> l:=e::!l),
    (fun () -> let out = List.rev !l in l:=[]; out) in
  let add_to_curblock, flush_curblock =
    let l = ref [] in
    (fun e -> l:=e::!l),
    (fun () -> let out = List.rev !l in l:=[]; out) in
  let end_block_with lab s =
    add_block { label = lab; inner = flush_curblock (); last = s }
  in
  let rec new_block stms = match stms with
    | [] -> ()
    | LLABEL lab :: tl -> in_block lab tl
    | _ -> in_block (Label.new_label "block_entry") stms
  and in_block lab stms = match stms with
    | [] -> end_block_with lab (LJUMP donel)
    | ((LJUMP _ | LCJUMP _) as s) :: tl -> end_block_with lab s; new_block tl
    | LLABEL lab' :: _ -> end_block_with lab (LJUMP lab'); new_block stms
    | s :: tl -> add_to_curblock s; in_block lab tl
  in
  new_block stms; (flush_blocks (), donel)

(** III) traceSchedule *)

type tag = Done | Todo

let rec mk_block_tbl = function
  | [] -> Label.mkempty ()
  | b :: blocks -> Label.add b.label (b,Todo) (mk_block_tbl blocks)

let rec do_block tbl b rest =
  let lab = b.label in
  let tbl = Label.add lab (b,Done) tbl in
  let most = [LLABEL lab] @ b.inner in
  match b.last with
    | LJUMP lab ->
	(match Label.look lab tbl with
	   | Some(b',Todo) -> most @ do_block tbl b' rest
	   | _ -> most @ [b.last] @ getnext tbl rest)
    | LCJUMP(r,x,y,t,f) ->
        (match Label.look t tbl, Label.look f tbl with
	   | _, Some(b',Todo) -> most @ [b.last] @ do_block tbl b' rest
           | Some (b',Todo), _ ->
	       most @ [LCJUMP(IrUtil.notrel r,x,y,f,t)] @ do_block tbl b' rest
           | _ ->
	       let f' = Label.new_label "trace" in
	       let new_code = [LCJUMP(r,x,y,t,f'); LLABEL f'; LJUMP f] in
	       most @ new_code @ getnext tbl rest)
    | _ -> failwith "Canon: basic block not ending with a L(C)JUMP"

and getnext tbl = function
  | [] -> []
  | b :: rest ->
      match Label.look b.label tbl with
        | Some (_,Todo) -> do_block tbl b rest
        | _ -> getnext tbl rest

let rec simplify = function
  | [] -> []
  | (LJUMP l as a)::(LLABEL l' as b)::r ->
      if l=l' then simplify r else a::b::(simplify r)
  |  a::r -> a::(simplify r)

let traceSchedule (blocks,donel) =
  let block_tbl = mk_block_tbl blocks in
  simplify (getnext block_tbl blocks @ [LLABEL donel])
