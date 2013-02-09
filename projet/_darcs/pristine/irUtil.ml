(** IrUtil : various functions about Intermediate Representation code *)

open Ir

(** * Functions about relop *)

let notrel = function
  | EQ -> NE
  | NE -> EQ
  | LT -> GE
  | GE -> LT
  | LE -> GT
  | GT -> LE

let relop = function
  | EQ -> (=)
  | NE -> (<>)
  | LE -> (<=)
  | GE -> (>=)
  | LT -> (<)
  | GT -> (>)

(** * Functions about binop *)

let binop = function
  | PLUS -> (+)
  | MINUS -> (-)
  | MUL -> ( * )
  | DIV -> (/)
  | AND -> (land)
  | OR -> (lor)
  | XOR -> (lxor)
  | ARSHIFT -> (asr)
  | RSHIFT -> (lsr)
  | LSHIFT -> (lsl)


