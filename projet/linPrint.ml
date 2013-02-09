(** LinUtil : various functions about linearized code *)

open Symbol
open Temp
open Label

open Lin
(** * Raw display of linearized code *)


(** Optional tuning of the display: *)

(** 1) Should we try to obtain a compact display ? If so, we
    use hov (horiz-or-vert) formatting boxes instead of v boxes. *)

let compact = ref true

(** End of optional tuning *)


let say =  Format.fprintf

let box tt s =
  if !compact then say tt ("@[<1>"^^s^^"@]") else say tt ("@[<v1>"^^s^^"@]")
let boxv tt s = say tt ("@[<v1>"^^s^^"@]")

let pr_symb tt sy = say tt "\"%s\"" (string_of_symbol sy)

let rec pr_list sep f tt = function
  | [] -> ()
  | [a] -> say tt "@,"; f tt a
  | (a::r) -> say tt "@,"; f tt a; say tt sep; pr_list sep f tt r

let rec pr_stm tt = function
  | LLABEL lab -> box tt "LLABEL %a" pr_label lab
  | LJUMP e -> box tt "LJUMP(%a)" pr_label e
  | LCJUMP(r,a,b,t,f) ->
      box tt "LCJUMP(%s,@,%a,@,%a,@,%a,%a)"
	(IrPrint.pr_relop r) pr_exp a pr_exp b pr_label t pr_label f
  | LMOVETEMP(t,b) -> box tt "LMOVETEMP(@,%a,@,%a)" pr_temp t pr_exp b
  | LMOVEMEM(a,b) -> box tt "LMOVEMEM(@,%a,@,%a)" pr_exp a pr_exp b
  | LMOVETEMPCALL(t,e,el) ->
      box tt "LMOVECALL(@,%a,%a,[%a])" pr_temp t
	pr_label e (pr_list ";" pr_exp) el
  | LEXPCALL(e,el) ->
      box tt "LEXPCALL(@,%a,[%a])" pr_label e (pr_list ";" pr_exp) el


and pr_exp tt = function
  | LBINOP(p,a,b) ->
      box tt "LBINOP(%s,@,%a,@,%a)" (IrPrint.pr_binop p) pr_exp a pr_exp b
  | LMEM(e) -> box tt "LMEM(@,%a)" pr_exp e
  | LFP -> box tt "LFP"
  | LWORDMUL(e) -> box tt "LWORDMUL(%a)" pr_exp e
  | LTEMP t -> box tt "LTEMP %a" pr_temp t
  | LCONST i -> if i < 0 then box tt "CONST (%i)" i else box tt "CONST %i" i
  | LSTR l -> box tt "STR %a" pr_label l

let print_stm stm =
  let tt = Format.std_formatter in
  box tt "%a@." pr_stm stm

let print_exp e =
  let tt = Format.std_formatter in
  box tt "%a@." pr_exp e

let print_body (stms,e) =
  List.iter print_stm stms; print_exp e

(** Data structure for representing linearized/canonized programs *)

let pr_str tt (lbl, s) =
  box tt "%a:\t.asciiz \"%s\"@." pr_label lbl s

open Ir

let pr_proc tt proc =
  Printf.printf "# %s\n" (string_of_label proc.entry);
   box tt "%a@.@." (pr_list ";" pr_stm) (fst proc.code);
   box tt "%a@.@." pr_exp (snd proc.code)

let print p =
  let tt = Format.std_formatter in
  List.iter (pr_str tt) p.strings;
  List.iter (pr_proc tt) p.procs
