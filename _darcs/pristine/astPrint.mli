(** Printast : Raw printer for Abstract Syntax Terms *)

(** The generic version: *)

val print :
    (Format.formatter -> 'v -> unit) ->
      (Format.formatter -> 'fc -> unit) ->
	(Format.formatter -> 'fd -> unit) ->
	  Format.formatter -> ('v,'fc,'fd) Ast.exp -> unit

(** Specialized version *)

val print_raw : Ast.rawexp -> unit
val print_attr : Ast.attrexp -> unit

(** Optional tuning of the display: *)

(** 1) Should we try to obtain a compact display ? If so, we
    use hov (horiz-or-vert) formatting boxes instead of v boxes. *)

val compact : bool ref

(** 2) Should we display sequential SeqExp with the same indentation ? *)

val linear_seq : bool ref

(** End of optional tuning *)

