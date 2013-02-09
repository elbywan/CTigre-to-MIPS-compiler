open Format
open Ir
open MipsAsm

(** Pretty-print abstract assembly instructions in Mips syntax *)

let asm_of_binop = function
  | PLUS -> "add"
  | MINUS -> "sub"
  | MUL -> "mul"
  | DIV -> "div"
  | AND -> "and"
  | OR -> "or"
  | XOR -> "xor"
  | LSHIFT -> "sll"
  | RSHIFT -> "srl"
  | ARSHIFT -> "sra"

let asm_of_relop = function
  | EQ -> "beq"
  | NE -> "bne"
  | LT -> "blt"
  | GT -> "bgt"
  | LE -> "ble"
  | GE -> "bge"

let print_abstr_reg = function
  | Rfp -> "$fp"
  | Rsp -> "$sp"
  | Rra -> "$ra"
  | Rres -> "$v0"
  | Rtmp t -> Temp.string_of_temp t

let print_simpl_reg = function
  | Nfp -> "$fp"
  | Nsp -> "$sp"
  | Nra -> "$ra"
  | Nres -> "$v0"
  | Ndst -> "$t0"
  | Nsrc1 -> "$t1"
  | Nsrc2 -> "$t2"

(** [format] : display of an assembly instruction, given a printing
    function for regs. *)

let format sayreg tt = function
  | OP(o,d,s1,s2) -> fprintf tt "%s %s, %s, %s"
      (asm_of_binop o) (sayreg d) (sayreg s1) (sayreg s2)
  | OPI(o,d,s,i) -> fprintf tt "%s %s, %s, %d"
      (asm_of_binop o) (sayreg d) (sayreg s) i
  | BR(r,s1,s2,l) -> fprintf tt "%s %s, %s, %a"
      (asm_of_relop r) (sayreg s1) (sayreg s2) Label.pr_label l
  | BRI(r,s,i,l) -> fprintf tt "%s %s, %d, %a" (asm_of_relop r) (sayreg s)
	i Label.pr_label l
  | LW(d,i,s) -> fprintf tt "lw %s, %d(%s)" (sayreg d) i (sayreg s)
  | SW(s1,i,s2) -> fprintf tt "sw %s, %d(%s)" (sayreg s1) i (sayreg s2)
  | LA (d,l) -> fprintf tt "la %s, %a" (sayreg d) Label.pr_label l
  | LI (d,i) -> fprintf tt "li %s, %d" (sayreg d) i
  | J l -> fprintf tt "j %a" Label.pr_label l
  | JAL l -> fprintf tt "jal %a" Label.pr_label l
  | JR s -> fprintf tt "jr %s" (sayreg s)
  | MOV (d,s) -> fprintf tt "move %s, %s" (sayreg d) (sayreg s)
  | LBL l -> fprintf tt "%a:\n" Label.pr_label l
  | COMM s -> fprintf tt "%s" s

let pr_str tt (lbl, s) =
  print_string "\t.data\n";
  fprintf tt "%a:\t.asciiz %S@." Label.pr_label lbl s

let pr_proc tt pr proc =
  print_string "\n\t.text\n";
  fprintf tt "# %a\n" Label.pr_label proc.entry;
  fprintf tt "%a@.@." pr proc.code

let print_asm sayreg (p: 'a MipsAsm.instrs Ir.prog) =
  let pr tt l =
    List.iter (fun i -> Format.fprintf tt "%a\n" (format sayreg) i) l in
  let tt = Format.std_formatter in
  List.iter (pr_str tt) p.strings;
  List.iter (pr_proc tt pr) p.procs
