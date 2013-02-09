(** Temp : representation of temporary pseudo-registers and labels *)

type temp = int

let string_of_temp t = "t"^string_of_int t
let pr_temp tt t = Format.fprintf tt "t%d" t

let temp_count = ref 99
(** Nota Bene: new temps are generated above 100, to avoid confusion
    with real registers *)

let new_temp () =
  incr temp_count;
  !temp_count

