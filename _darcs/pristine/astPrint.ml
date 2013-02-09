(** Printast : Raw printer for Abstract Syntax Terms *)

open Ast
open Symbol
open Label
open Temp

(** Optional tuning of the display: *)

(** 1) Should we try to obtain a compact display ? If so, we
    use hov (horiz-or-vert) formatting boxes instead of v boxes. *)

let compact = ref false

(** 2) Should we display sequential SeqExp with the same indentation ? *)

let linear_seq =ref false

(** End of optional tuning *)

let say =  Format.fprintf

let box tt s =
  if !compact then say tt ("@[<1>"^^s^^"@]") else say tt ("@[<v1>"^^s^^"@]")

let box0 tt s =
  if !compact then say tt ("@[<0>"^^s^^"@]") else say tt ("@[<v0>"^^s^^"@]")

let box_seq = if !linear_seq then box0 else box


let rec pr_list f tt = function
  | [] -> ()
  | [a] -> say tt "@,"; f tt a
  | (a::r) -> say tt "@,"; f tt a; say tt ", "; pr_list f tt r

let pr_opt f tt = function
  | None -> say tt "None"
  | Some e -> say tt "Some(%a)" f e

let pr_opti s tt = function
  | None -> ()
  | Some i -> say tt s i

let pr_opta s f tt = function
  | None -> ()
  | Some e -> say tt s f e

let pr_symb tt sy = say tt "%s" (string_of_symbol sy)

let pr_op = function
  | PlusOp -> "PlusOp"
  | MinusOp -> "MinusOp"
  | TimesOp -> "TimesOp"
  | DivideOp -> "DivideOp"
  | EqOp -> "EqOp"
  | NeqOp -> "NeqOp"
  | LtOp -> "LtOp"
  | LeOp -> "LeOp"
  | GtOp -> "GtOp"
  | GeOp -> "GeOp"
  | AndOp -> "AndOp"
  | OrOp -> "OrOp"

let print pr_v pr_fc pr_fd tt exp =
  let rec pr_var tt = function
    | SimpleVar v -> box tt "Simplevar(%a)" pr_v v
    | FieldVar(v,s) -> box tt "FieldVar(@,%a,@,%a)" pr_var v pr_symb s
    | SubscriptVar(v,e) -> box tt "SubscriptVar(@,%a,@,%a)" pr_var v pr_exp e

  and pr_exp tt = function
    | VarExp v -> box tt "VarExp(@,%a)" pr_var v
    | NilExp -> box tt "NilExp"
    | IntExp i -> box tt "IntExp(%i)" i
    | StringExp(s) -> box tt "StringExp(\"%s\")" (String.escaped s)
    | CharExp(c) -> box tt "CharExp('%c')" c
    | Apply(f,args) ->
	box tt "Apply(%a,[%a])" pr_fc f (pr_list pr_exp) args
    | Opexp(oper,left,right) ->
	box tt "OpExp(%s,@,%a,@,%a)"
	  (pr_op oper) pr_exp left pr_exp right
    | RecordExp(fields,typ) ->
	box tt "RecordExp(%a,[%a])"
	  pr_symb typ (pr_list pr_field) fields
    | SeqExp(e1,e2) ->
	box_seq tt "SeqExp[%a]" (pr_list pr_exp) [e1;e2]
    | AssignExp(v,e) ->
	box tt "AssignExp(@,%a,@,%a)" pr_var v pr_exp e
    | IfExp(test,then',else') ->
	box tt "IfExp(@,%a,@,%a%a)"
	  pr_exp test
	  pr_exp then'
	  (pr_opta ",@,%a" pr_exp) else'
    | WhileExp(test,body) ->
	box tt "WhileExp(@,%a,@,%a)" pr_exp test pr_exp body
    | ForExp f ->
	let pr_dir tt = function
	  | Up -> ()
	  | Down -> say tt ",@,Down"
	in
	box tt "ForExp(%a,@,%a,@,%a%a,@,%a)"
	  pr_v f.for_var pr_exp f.for_lo pr_exp f.for_hi
	  pr_dir f.for_dir pr_exp f.for_body
    | ArrayExp a ->
	box tt "ArrayExp(%a,@,%a,@,%a)"
	  pr_symb a.a_typ pr_exp a.a_size pr_exp a.a_init
    | LetVarExp(decs,body) ->
	box tt "LetVarExp([%a],@,%a)" (pr_list pr_vardec) decs pr_exp body
    | LetFunExp(decs,body) ->
	box tt "LetFunExp([%a],@,%a)" (pr_list pr_fundec) decs pr_exp body
    | TypeExp(tdecs,body) ->
	box tt "TypeExp([%a],@,%a)" (pr_list pr_typedec) tdecs pr_exp body

  and pr_fundec tt f =
    box tt "(%a,@[<1>[%a]@],%a,@,%a)"
      pr_fd f.fun_id
      (pr_list pr_param) f.fun_params
      (pr_opt pr_symb) f.fun_res
      pr_exp f.fun_body

  and pr_vardec tt v =
    box tt "VarDec(%a,%a,@,%a)"
      pr_v v.var_id
      (pr_opt pr_symb) v.var_typ
      pr_exp v.var_init

  and pr_typ tt = function
    | Typ_alias s -> box tt "Typ_name(%a)" pr_symb s
    | Typ_array s -> box tt "Typ_array(%a)" pr_symb s
    | Typ_record l -> box tt "Typ_record[%a]" (pr_list pr_fieldtyp) l

  and pr_typedec tt (name,t) = box tt "(%a,%a)" pr_symb name pr_typ t

  and pr_fieldtyp tt f = box tt "(%a,%a)" pr_symb f.fi_name pr_symb f.fi_typ

  and pr_param tt p =
    box tt "(%a%a)" pr_symb p.p_name (pr_opta ",%a" pr_symb) p.p_typ

  and pr_field tt (name,e) = box tt "(%a,%a)" pr_symb name pr_exp e
  in
  box tt "%a@." pr_exp exp

(** Specialized version for Ast.rawexp and Ast.attrexp *)

let print_raw = print pr_symb pr_symb pr_symb Format.std_formatter

let pr_attrvar tt v = match v.v_pos with
  | Stack(l,o) ->
      Format.fprintf tt "%a,{lev=%i,off=%i}" pr_symb v.v_name l o
  | Temp t -> Format.fprintf tt "%a,{temp=%a}"
	 pr_symb v.v_name pr_temp t

let pr_attrfundef tt {f_name=name;f_level=lvl} =
    Format.fprintf tt "%a,{lev=%d}" pr_symb name lvl

let pr_attrfuncall tt f = match f with
| Predefined s -> Format.fprintf tt "%a{Predefined}" pr_label s  
| Internal f -> Format.fprintf tt "%a{Internal,lev=%d}" pr_symb f.f_name f.f_level

let print_attr = print pr_attrvar pr_attrfuncall pr_attrfundef Format.std_formatter
