(** * Raw display of Intermediate Representation code *)

open Temp
open Label

open Ir

let relopname = function
  | EQ -> "="
  | NE -> "<>"
  | LE -> "<="
  | GE -> ">="
  | LT -> "<"
  | GT -> ">"

let pr_relop = function
  | EQ -> "EQ"
  | NE -> "NE"
  | LT -> "LT"
  | GT -> "GT"
  | LE -> "LE"
  | GE -> "GE"

let binopname = function
  | PLUS -> "+"
  | MINUS -> "-"
  | MUL -> "*"
  | DIV -> "/"
  | AND -> "land"
  | OR -> "lor"
  | XOR -> "lxor"
  | ARSHIFT -> "asr"
  | RSHIFT -> "lsr"
  | LSHIFT -> "lsl"

let pr_binop = function
  | PLUS -> "PLUS"
  | MINUS -> "MINUS"
  | MUL -> "MUL"
  | DIV -> "DIV"
  | AND -> "AND"
  | OR -> "OR"
  | XOR -> "XOR"
  | LSHIFT -> "LSHIFT"
  | RSHIFT -> "RSHIFT"
  | ARSHIFT -> "ARSHIFT"

(** Optional tuning of the display: *)

(** 1) Should we try to obtain a compact display ? If so, we
    use hov (horiz-or-vert) formatting boxes instead of v boxes. *)

let compact = ref true

(** End of optional tuning *)

let say =  Format.fprintf

let box tt s =
  if !compact then say tt ("@[<1>"^^s^^"@]") else say tt ("@[<v1>"^^s^^"@]")
let boxv tt s = say tt ("@[<v1>"^^s^^"@]")

let rec pr_list sep f tt = function
  | [] -> ()
  | [a] -> say tt "@,"; f tt a
  | (a::r) -> say tt "@,"; f tt a; say tt sep; pr_list sep f tt r

let rec pr_stm tt = function
  | LABEL lab -> box tt "LABEL %a" pr_label lab
  | JUMP e -> box tt "JUMP(%a)" pr_label e
  | CJUMP(r,a,b,t,f) ->
      box tt "CJUMP(%s,@,%a,@,%a,@,%a,%a)"
	(pr_relop r) pr_exp a pr_exp b pr_label t pr_label f
  | MOVE(a,b) -> box tt "MOVE(@,%a,@,%a)" pr_exp a pr_exp b
  | EXP e -> box tt "EXP(@,%a)" pr_exp e

and pr_exp tt = function
  | BINOP(p,a,b) ->
      box tt "BINOP(%s,@,%a,@,%a)" (pr_binop p) pr_exp a pr_exp b
  | MEM(e) -> box tt "MEM(@,%a)" pr_exp e
  | FP -> box tt "FP"
  | WORDMUL(e) -> box tt "WORDMUL(%a)" pr_exp e
  | TEMP t -> box tt "TEMP %a" pr_temp t
  | ESEQ(s,e) -> boxv tt "ESEQ([%a],@,%a)" (pr_list "; " pr_stm) s pr_exp e
  | CONST i -> if i < 0 then box tt "CONST (%i)" i else box tt "CONST %i" i
  | STR l -> box tt "STR %a" pr_label l
  | CALL(e,el) -> box tt "CALL(@,%a,[%a])" Label.pr_label e (pr_list ";" pr_exp) el


let print_stm stm =
  let tt = Format.std_formatter in
  box tt "%a@." pr_stm stm

let print_exp e =
  let tt = Format.std_formatter in
  box tt "%a@." pr_exp e

let pr_str tt (lbl, s) =
  print_string "\t.data\n";
  say tt "%a:\t.asciiz %S@." pr_label lbl s

let pr_proc tt pr proc =
  print_string "\n\t.text\n";
  say tt "# %a\n" pr_label proc.entry;
  say tt "%a@.@." pr proc.code

let print p =
  let tt = Format.std_formatter in
  List.iter (pr_str tt) p.strings;
  List.iter (pr_proc tt pr_exp) p.procs
