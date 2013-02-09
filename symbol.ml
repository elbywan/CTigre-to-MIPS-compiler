(** Symbols and association tables indexed by symbols *)

exception CannotFind of string

type symbol = string
let symbol n = n
let name s = s

let equal = (=)

let pr_symb tt sy = Format.fprintf tt "\"%s\"" sy
let string_of_symbol s = s

module SymMap = Map.Make(struct type t = symbol let compare = compare end)
type 'a table = 'a SymMap.t
let mkempty () = SymMap.empty
let add k v table = SymMap.add k v table
let iter f table = SymMap.iter f table
let find n table = try SymMap.find n table with _ -> raise (CannotFind ("Cannot find "^n))
let look n table = try Some(SymMap.find n table) with Not_found -> None
let addlist l t = List.fold_left (fun t -> fun (k,v) -> add k v t) t l
let maketable l = addlist l (mkempty ())
