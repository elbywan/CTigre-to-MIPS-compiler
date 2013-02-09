(** Ast : Abstract Syntax Tree for the Ctigre language *)

open Symbol
open Label

type direction_flag = Up | Down

type oper =
  | PlusOp | MinusOp | TimesOp | DivideOp
  | AndOp | OrOp
  | EqOp | NeqOp | LtOp | LeOp | GtOp | GeOp

type typename = symbol
type fieldname = symbol

type core_type =
  | Typ_alias of typename
  | Typ_array of typename
  | Typ_record of field list

and field = { fi_name: fieldname; fi_typ: typename }

type typedec = symbol * core_type


(** The type of ctigre expressions, parametrized by the type of
    variable symbols and function symbols (at call site and at definition) *)

type ('v,'fc, 'fd) exp =
  | VarExp of ('v,'fc, 'fd) var
  | NilExp
  | IntExp of int
  | StringExp of string
  | CharExp of char
  | Apply of 'fc * ('v,'fc, 'fd) exp list
  | RecordExp of (fieldname * ('v,'fc, 'fd) exp) list * typename
  | SeqExp of ('v,'fc, 'fd) exp * ('v,'fc, 'fd) exp
  | IfExp of ('v,'fc, 'fd) exp * ('v,'fc, 'fd) exp * ('v,'fc, 'fd) exp option
  | WhileExp of ('v,'fc, 'fd) exp * ('v,'fc, 'fd) exp
  | ForExp of ('v,'fc, 'fd) forexp
  | LetVarExp of ('v,'fc, 'fd) vardec list * ('v,'fc, 'fd) exp
  | LetFunExp of ('v,'fc, 'fd) fundec list * ('v,'fc, 'fd) exp
  | TypeExp of typedec list * ('v,'fc, 'fd) exp
  | ArrayExp of ('v,'fc, 'fd) arrayexp
  | Opexp of oper * ('v,'fc, 'fd) exp * ('v,'fc, 'fd) exp
  | AssignExp of ('v,'fc, 'fd) var * ('v,'fc, 'fd) exp

and ('v,'fc, 'fd) var =
  | SimpleVar of 'v
  | FieldVar of ('v,'fc, 'fd) var * fieldname
  | SubscriptVar of ('v,'fc, 'fd) var * ('v,'fc, 'fd) exp

and ('v,'fc, 'fd) forexp =
    { for_var: 'v; for_lo: ('v,'fc, 'fd) exp; for_hi: ('v,'fc, 'fd) exp;
      for_dir: direction_flag; for_body: ('v,'fc, 'fd) exp }

and ('v,'fc, 'fd) arrayexp = { a_typ: typename; a_size: ('v,'fc, 'fd) exp;
			       a_init: ('v,'fc, 'fd) exp }

and ('v,'fc, 'fd) vardec = { var_id: 'v; var_typ: typename option;
			     var_init: ('v,'fc, 'fd) exp}

and ('v,'fc, 'fd) fundec = { fun_id: 'fd; fun_params: param list;
			     fun_res: typename option;
			     fun_body: ('v,'fc, 'fd) exp}

and param = { p_name: symbol; p_typ: typename option }

(** The two instance of [exp] we will use:
    - [rawexp] will simply have [symbol] for variables and functions (call and def)
    - [attrexp] will have - Temp or level/ofsset for variables,
                          - Symbol and level for function definition,
                          - Internal or predefined for function call.
      (resp. functions).
*)

type rawexp = (symbol,symbol,symbol) exp

type varpos =
  | Stack of int * int (** Allocation in the stack (level, offset) *)
  | Temp of Temp.temp (** Allocation in a temp *)

type attrvar = { v_name: symbol; mutable v_pos: varpos }
 (** For doing escape analysis, it could convenient to have a mutable
     [v_pos].  Otherwise, just forget about it... *)

type attrfundef = { f_name: symbol; f_level: int; }

type attrfuncall =
  | Internal of attrfundef
  | Predefined of lbl

type attrexp = (attrvar, attrfuncall, attrfundef) exp
