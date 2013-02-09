(** IrUtil : various functions about Intermediate Representation code *)

open Ir

(** * Functions about relop *)

val notrel : relop -> relop
val relop : relop -> int -> int -> bool

(** * Functions about binop *)

val binop : binop -> int -> int -> int

