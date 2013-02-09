open Temp

(** Display registers *)

val print_abstr_reg : MipsAsm.abstr_reg -> string
val print_simpl_reg : MipsAsm.simpl_reg -> string
(*HIDE*)
(* val print_concr_reg : Asm.concr_reg -> string *)
(*END*)

(** [format] : display of an assembly instruction, given a printing
    function for regs. *)

val format:
    ('reg -> string) -> Format.formatter -> 'reg MipsAsm.instr -> unit

(** [print_asm] : global file formatter *)

val print_asm:
    ('reg -> string) -> 'reg MipsAsm.instrs Ir.prog -> unit

