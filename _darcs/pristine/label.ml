
type lbl = string

let pr_label tt sy = Format.fprintf tt "%s" sy

let lbl_count = ref ~-1

let new_label suffix =
  incr lbl_count;
  Format.sprintf "L%03d__%s" !lbl_count suffix

let string_of_label l = l

let main = "main"
let print = "print"
let printint = "printint"
let getchar = "getchar"
let getstring = "getstring"
let readint = "readint"
let ord = "ord"
let chr = "chr"
let mkstring = "mkstring"
let size = "size"
let concat = "concat"

let malloc = "malloc"
let exit = "exit"

let lbl_list = [main;print;printint;getchar;getstring;readint;ord;chr;mkstring;size;concat]

module LblMap = Map.Make(struct type t = lbl let compare = compare end)
type 'a table = 'a LblMap.t
let mkempty () = LblMap.empty
let add k v table = LblMap.add k v table
let iter f table = LblMap.iter f table
let find n table = try LblMap.find n table with _ -> failwith ("Cannot find "^n)
let look n table = try Some(LblMap.find n table) with Not_found -> None
let addlist l t = List.fold_left (fun t -> fun (k,v) -> add k v t) t l
let maketable l = addlist l (mkempty ())
