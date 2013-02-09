(** LinUtil : various functions about Linearized Intermediate Representation code *)

(** * Raw display of Linearized code *)

val print: Lin.lin -> unit

val print_stm: Lin.stm -> unit
val print_exp: Lin.exp -> unit
val print_body: Lin.funbody -> unit

(** Optional tuning of the display: *)

(** 1) Should we try to obtain a compact display ? If so, we
    use hov (horiz-or-vert) formatting boxes instead of v boxes. *)

val compact : bool ref

(** End of optional tuning *)
