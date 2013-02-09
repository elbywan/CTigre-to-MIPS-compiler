open Ast
open Symbol

let rec print_oper oper = match oper with 
	| PlusOp -> print_string "+" | MinusOp -> print_string "-" | TimesOp -> print_string "*" | DivideOp -> print_string "/" 
	| AndOp -> print_string "&" | OrOp -> print_string "|" 
	| EqOp -> print_string "=" | NeqOp -> print_string "-" | LtOp -> print_string "<" | LeOp -> print_string "<=" | GtOp -> print_string ">"  
	| GeOp -> print_string ">=" 

and print_var v tt = match v with
	| SimpleVar v -> tt v
        | FieldVar (v,s) -> print_var v tt; print_string("."); tt s
	| SubscriptVar (v,exp) -> print_var v tt; print_string("["); print_exp exp tt; print_string("]")

and print_elist el tt = match el with
	| [] -> ()
	| e::[] -> print_exp e tt
	| e1::e2 -> print_exp e1 tt; print_string(","); print_elist e2 tt

and print_fundec fl tt = match fl with
	| []  ->   print_string(" in\n");
	| [f] ->   tt f.fun_id; print_string("(");print_parl f.fun_params tt; print_string(")");
		   (fun z -> match z with | Some t -> print_string(":"); tt t | None -> ()) f.fun_res; 
		   print_string(" = \n"); print_exp f.fun_body tt;
	           print_string(" in\n");
	| f::f2 -> tt f.fun_id; print_string("(");print_parl f.fun_params tt; print_string(")");
		   (fun z -> match z with | Some t -> print_string(":"); tt t | None -> ()) f.fun_res; 
		   print_string(" = \n"); print_exp f.fun_body tt; print_string("\nand ");
		   print_fundec f2 tt

and print_vardec vl tt = match vl with
	| []  ->   print_string(" in\n");
	| [v] ->   tt v.var_id; 
		   (fun z -> match z with | Some t -> print_string(":"); tt t | None -> ()) v.var_typ;
		   print_string(" := "); print_exp v.var_init tt; print_string(" in\n");
	| v::v2 -> tt v.var_id; 
		   (fun z -> match z with | Some t -> print_string(":"); tt t | None -> ()) v.var_typ;
		   print_string(" := "); print_exp v.var_init tt; print_string("\nand ");
		   print_vardec v2 tt

and print_typedec tl tt = match tl with
	| []  ->   print_string("in\n");
	| [t] ->   tt (fst t); 
		   print_string(" = "); print_coretype (snd t) tt; print_string("in\n");
	| t::t2 -> tt (fst t); 
		   print_string(" = "); print_coretype (snd t) tt; print_string("\nand ");
		   print_typedec t2 tt

and print_coretype c tt = match c with
	| Typ_alias t -> tt t; print_string(" ");
	| Typ_array t -> print_string("array of "); tt t; print_string(" ")
	| Typ_record fl -> print_string("{ "); print_fieldl fl tt; print_string(" } ");

and print_fieldl fl tt = match fl with
	| [] -> ()
	| [f] -> tt f.fi_name; print_string(":"); tt f.fi_typ
	| f::f2 -> tt f.fi_name; print_string(":"); tt f.fi_typ; print_string(", ");
		   print_fieldl f2 tt

and print_parl pl tt = match pl with
	| [] -> ()
	| p::[] -> tt p.p_name; (fun z -> match z with | Some t -> print_string(":"); tt t | None -> ()) p.p_typ
	| p::p2 -> tt p.p_name; (fun z -> match z with | Some t -> print_string(":"); tt t | None -> ()) p.p_typ; print_string(","); print_parl p2 tt

and print_arrayexp aexp tt = 
	tt aexp.a_typ; print_string(" ["); print_exp aexp.a_size tt; print_string("]"); print_string(" of "); print_exp aexp.a_init tt; print_string(" ")

and print_record rc tt = 
	tt (snd rc); print_string(" { "); 
	let rec mch rc tt = match rc with | [] -> print_string(" } ") 
					  | [r] -> tt (fst r); print_string(" = "); print_exp (snd r) tt; print_string(" } ")
                                          | r::r2 -> tt (fst r); print_string(" = "); print_exp (snd r) tt; print_string(", "); mch r2 tt 
	in mch (fst rc) tt

and print_exp exp tt = match exp with
	| VarExp v -> print_var v tt
	| Apply (n, e_list) -> tt n; print_string("("); print_elist e_list tt; print_string(")");
	| IntExp i -> print_int i
	| NilExp -> print_string("nil ")
	| StringExp s -> print_char('"'); print_string s; print_char('"')
	| CharExp c -> print_char('\''); print_char c; print_char('\'')
	| RecordExp (f_e_list,typename) -> print_record (f_e_list,typename) tt
	| SeqExp (e,e2) -> print_exp e tt; print_string(";\n"); print_exp e2 tt
	| IfExp (eif,ethen,eelse) -> print_string("if "); print_exp eif tt;
				     print_string(" then "); print_exp ethen tt; print_string("\n");
				     ( fun eelse -> match eelse with | None -> () | Some e -> print_string("else "); print_exp e tt) eelse;
				     print_string(" ");
	| WhileExp (ewhile,edo) -> print_string("while "); print_exp ewhile tt; print_string(" do \n"); print_exp edo tt; print_string("\ndone"); 
	| ForExp f -> print_string("for "); tt f.for_var; print_string(" = "); 
		      print_exp f.for_lo tt; print_string(" to "); print_exp f.for_hi tt; 
		      print_string(" do \n"); print_exp f.for_body tt; print_string("\ndone"); 
	| LetVarExp (v_list,e) -> print_string ("var "); print_vardec v_list tt; print_exp e tt
	| LetFunExp (funlist,e) -> print_string("function "); print_fundec funlist tt; print_exp e tt
	| TypeExp (typelist,e) -> print_string("type "); print_typedec typelist tt; print_exp e tt
	| ArrayExp array_e -> print_arrayexp array_e tt
	| Opexp (op,e1,e2) -> print_string("("); print_exp e1 tt; print_oper op; print_exp e2 tt; print_string(")");
	| AssignExp (var,e) ->  print_var var tt; print_string(" := "); print_exp e tt

and print (raw:Ast.rawexp) = print_exp raw (fun sy -> print_string(Symbol.string_of_symbol sy))