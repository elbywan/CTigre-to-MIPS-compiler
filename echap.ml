open Ast
open Symbol
open Temp

type echap_type = 
	| Def_declared of symbol * int * int
	| Call_found of symbol * int * int

let rec set_new_echap el name lev off = match el with
	| [] -> []
	| h::t -> match h with 
		| Def_declared (n,level,offset) -> if (string_of_symbol name) = (string_of_symbol n) && level = lev && offset = off then  Call_found (n,level,offset)::t 
						   else h::(set_new_echap t name lev off) 
		| Call_found (n,level,offset) -> if (string_of_symbol name) = (string_of_symbol n) && level = lev && offset = off then  Call_found (n,level,offset)::t 
						 else h::(set_new_echap t name lev off) 

and pop_echap_elem el = match el with
	| [] -> assert false
	| h::t -> (h,t)

and print_vechap v = 
	print_string ("(begin) [");
	let rec recprint v = match v with
		| [] -> print_string("] (end)\n\n");
		| h::t -> print_string(" "); 
			  let _ = match h with | Def_declared (name,lev,off) -> print_string (string_of_symbol name); print_string("(Temp ");
										print_int lev; print_string("/"); print_int off; print_string(") ")
					       | Call_found (name,lev,off) -> print_string (string_of_symbol name); print_string("(Stack ");
									      print_int lev; print_string("/"); print_int off; print_string(") ")
			  in recprint t
	in recprint v

and vechap = ref [] 

and echap_exp exp l o venv = match exp with
	| NilExp -> NilExp
	| IntExp i -> IntExp i
	| StringExp s -> StringExp s
	| CharExp c -> CharExp c
	| Opexp (op,e1,e2) -> Opexp(op, echap_exp e1 l o venv, echap_exp e2 l o venv)
	| VarExp v -> VarExp (echap_var v l o venv)
	| AssignExp (var,e) ->  AssignExp (echap_var var l o venv, echap_exp e l o venv)
	| LetVarExp (v_list,e) -> let env_and_off = getechenv_vardec v_list venv o in
				  let newenv = fst (env_and_off) in
				  let vl = echap_vardec v_list l o newenv in
				  let o = snd (env_and_off) in
				  LetVarExp (vl, echap_exp e l o newenv)
	| LetFunExp (funlist,e) -> LetFunExp (echap_fundec funlist (l+1) 1 venv, echap_exp e l o venv)
	| TypeExp (typelist,e) -> TypeExp (typelist, echap_exp e l o venv)
	| Apply (n, e_list) -> Apply (n, echap_elist e_list l o venv) 
	| SeqExp (e,e2) -> SeqExp(echap_exp e l o venv, echap_exp e2 l o venv)
	| IfExp (eif,ethen,eelse) -> IfExp ( echap_exp eif l o venv, 
					     echap_exp ethen l o venv, 
					     (fun z -> match z with 
						| None -> None 
						| Some e -> Some (echap_exp e l o venv)
					     ) eelse )
	| WhileExp (ewhile,edo) -> WhileExp (echap_exp ewhile l o venv, echap_exp edo l o venv)
	| ForExp f ->   let elem = pop_echap_elem !vechap in
			let _ = vechap := snd (elem) in
			let ret = match fst elem with 
			| Def_declared (n,l,o) -> 
				let temp_int = new_temp() in
				let newvenv = add n { v_name = n; v_pos = Temp temp_int } venv in
				ForExp {for_var = { v_name = n; v_pos = Temp temp_int }; 
					for_lo = echap_exp f.for_lo l o venv; 
					for_hi = echap_exp f.for_hi l o venv;
					for_dir = f.for_dir; 
					for_body = echap_exp f.for_body l o newvenv}
			| Call_found (n,lev,off) -> 
				let newvenv = add n { v_name = n; v_pos = Stack (l,o) } venv in
				ForExp {for_var = { v_name = n; v_pos = Stack (l,o) }; 
					for_lo = echap_exp f.for_lo l o newvenv; 
					for_hi = echap_exp f.for_hi l o newvenv;
					for_dir = f.for_dir; 
					for_body = echap_exp f.for_body l o newvenv} 
			in ret
	| ArrayExp array_e -> ArrayExp { a_typ = array_e.a_typ; 
					 a_size = echap_exp array_e.a_size l o venv;
					 a_init = echap_exp array_e.a_init l o venv; }
	| RecordExp (f_e_list,typename) -> RecordExp (echap_record f_e_list l o venv, typename)

and echap_elist el l o venv = match el with
	| [] -> []
	| e::e2 -> (echap_exp e l o venv)::(echap_elist e2 l o venv)

and echap_var var l o venv = match var with
	| SimpleVar v -> SimpleVar (find v.v_name venv) 
        | FieldVar (v,s) -> FieldVar(echap_var v l o venv, s)
	| SubscriptVar (v,exp) -> SubscriptVar(echap_var v l o venv, echap_exp exp l o venv)

and echap_vardec vl l o venv = match vl with 
	| [] -> []
	| v::v2 -> let newid = (find v.var_id.v_name venv) in
		   match newid.v_pos with
		   | Temp _ ->  (({ var_id = newid; 
				    var_typ = v.var_typ; 
				    var_init = echap_exp v.var_init l o venv 
				}))::(echap_vardec v2 l o venv)
		   | Stack _ -> (({ var_id = newid; 
				    var_typ = v.var_typ; 
				    var_init = echap_exp v.var_init l (o+1) venv 
				}))::(echap_vardec v2 l (o+1) venv)

and getechenv_vardec vl venv o = match vl with
	| [] -> (venv, o)
	| v::v2 -> let elem = pop_echap_elem !vechap in
		   let _ = vechap := snd (elem) in
		   match fst elem with
			 | Def_declared (n,lev,off) -> 
				let temp_int = new_temp() in
				getechenv_vardec v2 (add n { v_name = n; v_pos = Temp temp_int } venv) o 
			 | Call_found (n,lev,off) -> 
				getechenv_vardec v2 (add n { v_name = n; v_pos = Stack (lev,o) } venv) (o+1)

and echap_fundec fl l o venv = match fl with
	| [] -> []
	| f::f2 ->  let newvenv = getechenv_plist f.fun_params l (-1) venv in
		    ({  fun_id = f.fun_id; 
			fun_params = f.fun_params;
			fun_res = f.fun_res;
			fun_body = echap_exp f.fun_body l 1 newvenv
		      })::(echap_fundec f2 l 1 venv) 

and getechenv_plist pl l o venv = match pl with
	| [] -> venv
	| p::p2 -> let newenv = add p.p_name { v_name = p.p_name; v_pos = Stack(l,o) } venv in
		   getechenv_plist p2 l (o-1) newenv

and echap_record rl l o venv = match rl with
	| [] -> []
	| r::r2 -> (fst r, echap_exp (snd r) l o venv)::(echap_record r2 l o venv)
