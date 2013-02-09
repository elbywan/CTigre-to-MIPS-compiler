(** Symbols and association tables indexed by symbols *)

exception CannotFind of string

type symbol

val symbol: string -> symbol

val pr_symb: Format.formatter -> symbol -> unit
val string_of_symbol: symbol -> string

type 'a table
val mkempty: unit -> 'a table
val add: symbol -> 'a -> 'a table -> 'a table
val find: symbol -> 'a table -> 'a
val iter: (symbol -> 'a -> unit) -> 'a table -> unit
val look: symbol -> 'a table -> 'a option
val addlist: (symbol * 'a) list -> 'a table -> 'a table
val maketable: (symbol * 'a) list -> 'a table

