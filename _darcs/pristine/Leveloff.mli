(**
Fonction de marquage de l'arbre de syntaxe avec les level et offset des variables.
Au cours du parcours de l'arbre on a modifié une référence vers une liste, qui contient les variables dans l'ordre de leur déclaration 
ainsi que les informations d'échappement, ce qui nous sera utile pour l'analyse d'échappement. 
Prend un entier en paramètre, utilisé comme un booléen pour autoriser / refuser l'analyse d'échappement. 
**)

val level : Ast.rawexp -> int -> Ast.attrexp 
