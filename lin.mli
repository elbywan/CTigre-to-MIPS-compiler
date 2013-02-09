(** Lin : a representation similar to Ir, but linearized *)

(** Compared with Ir, linearized expressions [Lin.exp] cannot contain
    statement parts (i.e. they are pure). More precisely:
     - 1. No [ESEQ]'s
     - 2. All [CALL] are now done in statements, either in the form
          of a [EXP(CALL(...))] or of a [MOVE(TEMP t,CALL(...))]

    Concerning linearized statements [Lin.stm]:
     - 3. No need for [EXP] except on a [CALL] : since any other expression
          is pure, it would have no effect, we can simply ignore it
     - 4. Since [ESEQ] is gone, we can only find [TEMP] or [MEM]
          as first argument of a [MOVE]

    See the module Canon for the production of such linearized
    expressions and statements.

*)

open Label
open Temp

type exp =
  | LBINOP of Ir.binop * exp * exp
  | LMEM of exp
  | LWORDMUL of exp
  | LFP
  | LTEMP of temp
  | LCONST of int
  | LSTR of lbl

type stm =
  | LLABEL of lbl
  | LJUMP of lbl
  | LCJUMP of Ir.relop * exp * exp * lbl * lbl
  | LMOVETEMP of temp * exp
  | LMOVEMEM of exp * exp
  | LMOVETEMPCALL of temp * lbl * exp list
  | LEXPCALL of lbl * exp list

type stms = stm list

(** After linearization, the body of a function will correspond
    to several instructions and a final pure expression containing
    the result *)

type funbody = stms * exp

(** Type of programme after "linearization". *)

type lin = funbody Ir.prog
