
(** Abstract type representing labels. *)
type lbl

val new_label: string -> lbl
(** [new_label] should produce a fresh label, i.e. a label not already
   created by an earlier [new_label] nor used in [runtime.s]. *)

val label: string -> lbl

val string_of_label: lbl -> string
val pr_label: Format.formatter -> lbl -> unit

(** Predefined label, see 'runtime.s' *)

val main: lbl
val print: lbl
val printint: lbl
val getchar: lbl
val getstring: lbl
val readint: lbl
val ord: lbl
val chr: lbl
val mkstring: lbl
val size: lbl
val concat: lbl

val malloc: lbl
val exit: lbl

val lbl_list : string list

(** Association tables indexed by label.
    It's useful for IrInterp and Canon.traceSchedule *)

type 'a table
val mkempty: unit -> 'a table
val add: lbl -> 'a -> 'a table -> 'a table
val find: lbl -> 'a table -> 'a
val iter: (lbl -> 'a -> unit) -> 'a table -> unit
val look: lbl -> 'a table -> 'a option
val addlist: (lbl * 'a) list -> 'a table -> 'a table
val maketable: (lbl * 'a) list -> 'a table
