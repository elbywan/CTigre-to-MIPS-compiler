(** MipsAsm : an abstract representation for mips assembly instructions *)

open Temp
open Label

(** The type of instructions, parametrized by the type of registers *)

type 'reg instr =
  | OP of Ir.binop * 'reg * 'reg * 'reg
           (** Arithmetical operation on registers *)
  | OPI of Ir.binop * 'reg * 'reg * int
           (** Same, with immediate 2nd operand *)
  | BR of Ir.relop * 'reg * 'reg * lbl (** Conditional branching *)
  | BRI of Ir.relop * 'reg * int * lbl (** Same, with immediate 2nd operand *)
  | LW of 'reg * int * 'reg           (** lw reg1, int(reg2) *)
  | SW of 'reg * int * 'reg           (** sw reg1, int(reg2) *)
  | LA of 'reg * lbl
  | LI of 'reg * int
  | J of lbl
  | JAL of lbl
  | JR of 'reg
  | MOV of 'reg * 'reg
  | LBL of lbl
  | COMM of string

type 'reg instrs = 'reg instr list

(** Abstract registers without any allocation *)

type abstr_reg =
  | Rfp   (** frame pointer *)
  | Rsp   (** stack pointer *)
  | Rra   (** return address *)
  | Rres  (** result of function call ($v0 in Mips) *)
  | Rtmp of temp (** temporaries before allocation *)

type abstr_instr = abstr_reg instr
type abstr_instrs = abstr_instr list

(** Registers for naive allocation *)

type simpl_reg =
  | Nfp
  | Nsp
  | Nra
  | Nres
  | Ndst  (** abstract register, used as destination for naive allocation *)
  | Nsrc1 (** idem, first source for naive allocation *)
  | Nsrc2 (** idem, second source for naive allocation *)

type simpl_instr = simpl_reg instr
type simpl_instrs = simpl_instr list

(*HIDE*)

(** Full set of registers, given by their numbers *)

type concr_reg = temp

type concr_instr = concr_reg instr
type concr_instrs = concr_instr list

(*END*)
