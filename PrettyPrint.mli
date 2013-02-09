open Printf
open Ast

(** PrettyPrinter vu en TP. Transforme un arbre de syntaxe abstraite en programme Ctigre. **)
val print: Ast.rawexp -> unit