(** Temp : representation of temporary pseudo-registers *)

type temp

val new_temp: unit -> temp

val pr_temp: Format.formatter -> temp -> unit
val string_of_temp: temp -> string

