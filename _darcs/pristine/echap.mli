open Ast
open Symbol

(** Type qui distingue les variables du programme qui échappent ou non. *)
type echap_type = 
	| Def_declared of symbol * int * int
	| Call_found of symbol * int * int

(** Modifie une variable dans la liste d'échappement, la marque comme variable qui échappe et retourne la liste modifiée. *)
val set_new_echap : echap_type list -> symbol -> int -> int -> echap_type list

(** Imprime la liste d'échappement. *)
val print_vechap : echap_type list -> unit

(** La liste d'échappement proprement dite. *)
val vechap : echap_type list ref

(** La fonction qui modifie l'arbre en ajoutant les temporaires aux variables qui n'échappent pas. *)
val echap_exp : Ast.attrexp -> int -> int -> Ast.attrvar Symbol.table -> Ast.attrexp