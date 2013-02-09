(** Abstract description of procedure and programme *)

open Label

type 'a proc_desc = {
    entry: lbl;   (** Entry point, will the prologue's lbl *)
    numargs: int; (** Number of argument *)
    numvars: int; (** Number of words in the frame for escaping variables *)
    code: 'a;     (** Procedure's code.
		      It would first be Ir.ext and then Lin.funbody *)
  }

type 'code prog = {
    strings: (lbl * string) list; (** List of strings to be declared in .data *)
    procs: 'code proc_desc list; (** List of procedure *)
  }

(** Ir : Intermediate Representation *)

type binop =
  | PLUS | MINUS | MUL | DIV
  | AND | OR
  | LSHIFT | RSHIFT | ARSHIFT | XOR

type relop = EQ | NE | LT | GT | LE | GE

type stm =
  | LABEL of lbl
  | JUMP of lbl
  | CJUMP of relop * exp * exp * lbl * lbl
  | MOVE of exp * exp
  | EXP of exp

and stms = stm list

and exp =
  | BINOP of binop * exp * exp
  | MEM of exp
  | WORDMUL of exp
  | FP
  | TEMP of Temp.temp
  | ESEQ of stms * exp
  | CONST of int
  | STR of lbl
  | CALL of lbl * exp list

(** Type of programme after "translation" and before "linearization". *)
type ir = exp prog
