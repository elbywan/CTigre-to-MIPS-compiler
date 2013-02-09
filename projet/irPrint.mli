(** Raw display of Intermediate Representation code *)

open Ir

val relopname : relop -> string
val pr_relop : relop -> string

val binopname : binop -> string
val pr_binop : binop -> string

val print_stm : Ir.stm -> unit
val print_exp : Ir.exp -> unit
val print : Ir.ir -> unit

(** Optional tuning of the display: *)

(** 1) Should we try to obtain a compact display ? If so, we
    use hov (horiz-or-vert) formatting boxes instead of v boxes. *)

val compact : bool ref

(** End of optional tuning *)
