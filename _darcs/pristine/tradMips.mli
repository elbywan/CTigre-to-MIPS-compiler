(** Fonction de traduction du code intermédiaire linéarisé vers de l'assembleur abstrait. **)

val tradAbstr : Lin.lin -> int -> MipsAsm.abstr_instrs Ir.prog