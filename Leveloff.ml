open Ast
open Symbol
open Echap

let rec level_exp exp l o venv fenv = match exp with
	| NilExp -> NilExp
	| IntExp i -> IntExp i
	| StringExp s -> StringExp s
	| CharExp c -> CharExp c
	| Opexp (op,e1,e2) -> Opexp(op, level_exp e1 l o venv fenv, level_exp e2 l o venv fenv)
	| VarExp v -> VarExp (level_var v l o venv fenv)
	| AssignExp (var,e) ->  AssignExp (level_var var l o venv fenv, level_exp e l o venv fenv)
	| LetVarExp (v_list,e) -> let newenv = getenv_vardec v_list l o venv in
				  let vl = level_vardec v_list l o newenv fenv in
				  LetVarExp (vl, level_exp e l (o+(List.length v_list)) newenv fenv)
	| LetFunExp (funlist,e) -> let newfenv = getenv_fundec funlist (l+1) 1 fenv in
				   LetFunExp (level_fundec funlist (l+1) 1 venv newfenv, level_exp e l o venv newfenv)
	| TypeExp (typelist,e) -> TypeExp (typelist, level_exp e l o venv fenv)
	| Apply (n, e_list) ->  let m = string_of_symbol n in
				let lbltable = Label.lbl_list in
				if (match (look n fenv) with | Some _ -> false | None -> true) 
				   && (List.exists (fun x -> if Label.string_of_label x = m then true else false) lbltable) then 
					Apply(Predefined (List.find (fun x -> if Label.string_of_label x = m then true else false) lbltable), 
					      level_elist e_list l o venv fenv)
				else Apply (Internal (find n fenv), level_elist e_list l o venv fenv) 
	| SeqExp (e,e2) -> SeqExp(level_exp e l o venv fenv, level_exp e2 l o venv fenv)
	| IfExp (eif,ethen,eelse) -> IfExp ( level_exp eif l o venv fenv, 
					     level_exp ethen l o venv fenv, 
					     (fun z -> match z with 
						| None -> None 
						| Some e -> Some (level_exp e l o venv fenv)
					     ) eelse )
	| WhileExp (ewhile,edo) -> WhileExp (level_exp ewhile l o venv fenv, level_exp edo l o venv fenv)
	| ForExp f ->  let newvenv = add f.for_var { v_name = f.for_var; v_pos = Stack (l,o) } venv in
		       vechap := (Def_declared (f.for_var,l,o))::(!vechap);
		       ForExp { for_var = { v_name = f.for_var; v_pos = Stack (l,o) }; 
				for_lo = level_exp f.for_lo l o venv fenv; 
				for_hi = level_exp f.for_hi l o venv fenv;
				for_dir = f.for_dir; 
				for_body = level_exp f.for_body l (o+1) newvenv fenv }
	| ArrayExp array_e -> ArrayExp { a_typ = array_e.a_typ; 
					 a_size = level_exp array_e.a_size l o venv fenv;
					 a_init = level_exp array_e.a_init l o venv fenv; }
	| RecordExp (f_e_list,typename) -> RecordExp (level_record f_e_list l o venv fenv, typename)	

and level_elist el l o venv fenv = match el with
	| [] -> []
	| e::e2 -> (level_exp e l o venv fenv)::(level_elist e2 l o venv fenv)

and level_var var l o venv fenv = match var with
	| SimpleVar v -> let found = (find v venv) in 
			 let _ = match found.v_pos with | Temp _ -> () 
						        | Stack (lev,off) -> if lev != l && off > 0 then 
										vechap := (set_new_echap !vechap v lev off) 
									     else () 
			 in SimpleVar (found)
        | FieldVar (v,s) -> FieldVar(level_var v l o venv fenv, s)
	| SubscriptVar (v,exp) -> SubscriptVar(level_var v l o venv fenv, level_exp exp l o venv fenv)

and level_vardec vl l o venv fenv = match vl with
	| [] -> []
	| v::v2 -> vechap := (Def_declared (v.var_id,l,o))::(!vechap);
		   ({ var_id = { v_name = v.var_id; v_pos = Stack (l,o) }; 
		      var_typ = v.var_typ; 
		      var_init = level_exp v.var_init l (o+1) venv fenv 
		    })::(level_vardec v2 l (o+1) venv fenv)

and getenv_vardec vl l o venv = match vl with
	| [] -> venv
	| v::v2 -> let newenv = add v.var_id { v_name = v.var_id; v_pos = Stack (l,o) } venv in
		   getenv_vardec v2 l (o+1) newenv

and level_fundec fl l o venv fenv = match fl with
	| [] -> []
	| f::f2 ->  let newvenv = getenv_plist f.fun_params l (-1) venv in
		    ({  fun_id = { f_name = f.fun_id; f_level = l }; 
			fun_params = f.fun_params;
			fun_res = f.fun_res;
			fun_body = level_exp f.fun_body l 1 newvenv fenv
		      })::(level_fundec f2 l 1 venv fenv) 

and getenv_fundec fl l o fenv = match fl with
	| [] -> fenv
	| f::f2 -> let newfenv = add f.fun_id { f_name = f.fun_id; f_level = l } fenv  in
		   getenv_fundec f2 l 1 newfenv

and getenv_plist pl l o venv = match pl with
	| [] -> venv
	| p::p2 -> let newenv = add p.p_name { v_name = p.p_name; v_pos = Stack(l,o) } venv in
		   getenv_plist p2 l (o-1) newenv

and level_record rl l o venv fenv = match rl with
	| [] -> []
	| r::r2 -> (fst r, level_exp (snd r) l o venv fenv)::(level_record r2 l o venv fenv)

and level (raw:Ast.rawexp) check = let basic_leveloff = (level_exp raw 1 1 (mkempty()) (mkempty())) in
			           if check = 1 then let _ = vechap := List.rev !vechap in 
			                             echap_exp basic_leveloff 1 1 (mkempty())
						else basic_leveloff
			(** For test purposes : **)
			(**  let _ = (level_exp raw 1 1 (mkempty()) (mkempty())) in
				print_vechap (List.rev !vechap);
				vechap := [];
				level_exp raw 1 1 (mkempty()) (mkempty())
			**)