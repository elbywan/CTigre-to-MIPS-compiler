open Ast
open Symbol
open PrettyPrint

exception TYPE_ERROR
exception TYPE_ENV_ERROR

let print_symbol s = print_string (string_of_symbol s)

type ty =
	| RECORD of ( Symbol.symbol * ty ) list
	| NIL
	| INT
	| CHAR
	| STRING
	| ARRAY of ty
	| NAME of Symbol.symbol * ty ref
	| UNIT
	| RECURSIVE

let rec ty_to_string ?(last_ref = []) t = match t with
	| RECORD l -> "RECORD ["^(let rec loop l = (match l with 
						    | [] -> ""
						    | [(a,b)] -> (ty_to_string ~last_ref:last_ref b)
						    | (a,b)::c -> (ty_to_string ~last_ref:last_ref b)^","^(loop c)) in loop l)^"]"
	| NIL -> "NIL"
	| INT -> "INT"
	| CHAR -> "CHAR"
	| STRING -> "STRING"
	| ARRAY l -> "ARRAY ["^ty_to_string ~last_ref:last_ref l^"]"
	| NAME (name,r) -> if List.for_all (fun a -> a != r) last_ref then (string_of_symbol name)^" ["^(ty_to_string ~last_ref:(r::last_ref) !r)^"]"
			   else (string_of_symbol name)
	| UNIT -> "UNIT"
	| RECURSIVE -> "RECURSIVE"

let init_tenv () = 
	let tenv = mkempty() in
	let tenv = add (symbol "nil") NIL tenv in
	let tenv = add (symbol "int") INT tenv in
	let tenv = add (symbol "char") CHAR tenv in
	let tenv = add (symbol "string") STRING tenv in
	let tenv = add (symbol "unit") UNIT tenv in
	tenv

let print_terror var ty texp match_str =
	print_string("[");
	print_string match_str;
	print_string "] type error : \n"; 
	print_string (ty_to_string texp);
	print_string " expected, instead :\nexpression > ( ";
	PrettyPrint.print var; print_string(" )\ntype > ( "); (print_string (ty_to_string ty));
	print_string " )\n"

let is_predefined n = 
	let rec z l = match l with
	| [] -> false
	| l::tail -> if (Label.string_of_label l = string_of_symbol n) then true
		     else z tail
        in z Label.lbl_list

let get_predefined n = match (string_of_symbol n) with
	| "main" -> UNIT
	| "print" -> UNIT
	| "printint" -> UNIT
	| "getchar" -> CHAR
	| "getstring" -> STRING
	| "readint" -> INT
	| "ord" -> INT
	| "chr" -> CHAR
	| "mkstring" -> STRING
	| "size" -> INT
	| "concat" -> STRING
	| _ -> UNIT

let rec check_predefined_args n l env fenv tenv recenv = match (string_of_symbol n) with
	| "main" -> if (List.length l) > 0 then begin print_string "\n[main] Invalid arg number. ("; print_int (List.length l); print_string ")\n"; end
	| "print" -> if (List.length l) != 1 then begin print_string "\n[print] Invalid arg number. ("; print_int (List.length l); print_string ")\n"; end
		     else let type_arg = (type_exp (List.hd l) env fenv tenv recenv) in
		     if type_arg != STRING then begin
			print_terror (List.hd  l) type_arg STRING "Print arg";
			raise TYPE_ERROR end else ()
	| "printint" -> if (List.length l) != 1 then begin print_string "\n[printint] Invalid arg number. ("; print_int (List.length l); print_string ")\n"; end
			else let type_arg = (type_exp (List.hd l) env fenv tenv recenv) in
			if type_arg != INT then begin
			   print_terror (List.hd l) type_arg INT "Printint arg";
			   raise TYPE_ERROR end else ()
	| "getchar" -> if (List.length l) > 0 then begin print_string "\n[getchar] Invalid arg number. ("; print_int (List.length l); print_string ")\n"; end
	| "getstring" -> if (List.length l) != 1 then begin print_string "\n[getstring] Invalid arg number. ("; print_int (List.length l); print_string ")\n"; end
			 else let type_arg = (type_exp (List.hd l) env fenv tenv recenv) in
			 if type_arg != STRING then begin
			   print_terror (List.hd l) type_arg STRING "Getstring arg";
			   raise TYPE_ERROR end else ()
	| "readint" -> if (List.length l) > 0 then begin print_string "\n[readint] Invalid arg number. ("; print_int (List.length l); print_string ")\n"; end
	| "ord" -> if (List.length l) != 1 then begin print_string "\n[ord] Invalid arg number. ("; print_int (List.length l); print_string ")\n"; end
		   else let type_arg = (type_exp (List.hd l) env fenv tenv recenv) in
		   if type_arg != CHAR then begin
			  print_terror (List.hd l) type_arg CHAR "Ord arg";
			  raise TYPE_ERROR end else ()
	| "chr" -> if (List.length l) != 1 then begin print_string "\n[chr] Invalid arg number. ("; print_int (List.length l); print_string ")\n"; end
		   else let type_arg = (type_exp (List.hd l) env fenv tenv recenv) in
		   if type_arg != INT then begin
			  print_terror (List.hd l) type_arg INT "Chr arg";
			  raise TYPE_ERROR end else ()
	| "mkstring" -> if (List.length l) != 1 then begin print_string "\n[mkstring] Invalid arg number. ("; print_int (List.length l); print_string ")\n"; end
		        else let type_arg = (type_exp (List.hd l) env fenv tenv recenv) in
			if type_arg != INT then begin
			  print_terror (List.hd l) type_arg INT "Mkstring arg";
			  raise TYPE_ERROR end else ()
	| "size" -> if (List.length l) != 1 then begin print_string "\n[size] Invalid arg number. ("; print_int (List.length l); print_string ")\n"; end
		    else let type_arg = (type_exp (List.hd l) env fenv tenv recenv) in
		    if type_arg != STRING then begin
			  print_terror (List.hd l) type_arg STRING "Size arg";
			  raise TYPE_ERROR end else ()
	| "concat" -> if (List.length l) != 2 then begin print_string "\n[concat] Invalid arg number. ("; print_int (List.length l); print_string ")\n"; end
		   else begin let type_arg1 = (type_exp (List.hd l) env fenv tenv recenv) in
		        let type_arg2 = (type_exp (List.nth l 1) env fenv tenv recenv) in
		        if type_arg1 != STRING then begin
			  print_terror (List.hd l) type_arg1 STRING "Concat arg1";
			  raise TYPE_ERROR
		        end else if type_arg2 != STRING then begin
			  print_terror (List.hd l) type_arg2 STRING "Concat arg2";
			  raise TYPE_ERROR
		        end else () end

	| _ -> ()

and type_exp exp env fenv tenv recenv = match exp with
	| NilExp -> NIL
	| IntExp i -> INT
	| StringExp s -> STRING
	| CharExp c -> CHAR
	| Opexp (op,e1,e2) -> let type_e1 = type_exp e1 env fenv tenv recenv
			      and type_e2 = type_exp e2 env fenv tenv recenv in
			      if type_e1 != type_e2 && type_e1 != RECURSIVE && type_e2 != RECURSIVE then begin 
				if ((match type_e1 with | NAME (_,r) -> (match !r with | RECORD _ -> true | _ -> false) | _ -> false) 
					&& (match type_e2 with | NIL -> true | _ -> false)) ||
				   ((match type_e2 with | NAME (_,r) -> (match !r with | RECORD _ -> true | _ -> false) | _ -> false) 
					&& (match type_e1 with | NIL -> true | _ -> false)) then INT 
				else begin print_terror e2 type_e2 type_e1 "Op";
					   raise TYPE_ERROR end
			      end else INT 
	| SeqExp (e,e2) -> ignore(type_exp e env fenv tenv recenv); type_exp e2 env fenv tenv recenv
	| IfExp (eif,ethen,eelse) -> let type_cond = (type_exp eif env fenv tenv recenv) in
				     let type_then = (type_exp ethen env fenv tenv recenv) in
				     if type_cond != INT then begin
					print_terror eif type_cond INT "If";
					raise TYPE_ERROR
				     end else begin
					( fun eelse -> match eelse with 
					  | None -> type_then
					  | Some e -> let type_else = (type_exp e env fenv tenv recenv) in
						      if type_then = RECURSIVE then type_else else
						      if type_else = RECURSIVE then type_then else
						      if ((match type_then with | NAME (_,r) -> (match !r with | RECORD _ -> true | _ -> false) | _ -> false) 
								&& (match type_else with | NIL -> true | _ -> false)) then type_then else 
						      if ((match type_else with | NAME (_,r) -> (match !r with | RECORD _ -> true | _ -> false) | _ -> false) 
								&& (match type_then with | NIL -> true | _ -> false)) then type_else else 
					              if (type_then != type_else) then begin
							print_string "[IF] type mismatch (";
							print_string (ty_to_string type_then); 
							print_string ",";
							print_string (ty_to_string type_else); 
							print_string ")\n";
							raise TYPE_ERROR
						      end else type_then ) 
					  eelse; 
				     end
	| WhileExp (ewhile,edo) -> let type_cond = (type_exp ewhile env fenv tenv recenv) in
				   let type_do = (type_exp edo env fenv tenv recenv) in
				   if type_cond != INT then begin
					print_terror ewhile type_cond INT "While";
					raise TYPE_ERROR
				   end else type_do
	| ForExp f -> let env = (add f.for_var INT env) in
		      let type_lo = (type_exp f.for_lo env fenv tenv recenv)
		      and type_hi = (type_exp f.for_hi env fenv tenv recenv)
		      and type_loop = (type_exp f.for_body env fenv tenv recenv) in
		      if (type_lo != INT) then begin
			print_terror f.for_lo type_lo INT "For_lo";
			raise TYPE_ERROR end else
		      if (type_hi != INT) then begin
			print_terror f.for_hi type_hi INT "For_hi";
			raise TYPE_ERROR end else
		      type_loop
	| VarExp v -> type_var v env fenv tenv recenv
	| AssignExp (var,e) -> let t_var = type_var var env fenv tenv recenv in
			       let e_type = type_exp e env fenv tenv recenv in
			       if t_var != e_type then begin
				  print_terror e e_type t_var "Assign";
				  raise TYPE_ERROR
			       end else UNIT
	| LetFunExp (funlist,e) -> type_exp e env (type_fundec funlist env fenv tenv) tenv recenv  
	| TypeExp (typelist,e) -> type_exp e env fenv (type_type typelist env fenv tenv) recenv
	| Apply (n, e_list) -> if is_predefined n then begin
				  check_predefined_args n e_list env fenv tenv recenv;
				  get_predefined n end else begin
			       let n_props = (find n fenv) in
			       let z e1 e2 =  let arg_type = type_exp e1 env fenv tenv recenv in
					      match e2.p_typ with 
					      | None -> (e2.p_name,arg_type)
					      | Some typ -> 
					      let param_type = (find typ tenv) in
					      if arg_type != param_type then begin
						print_terror e1 arg_type param_type "Function args type";
						raise TYPE_ERROR
					      end else (e2.p_name,arg_type);
			       in let env = addlist (List.map2 z e_list n_props.fun_params) env in
			       if List.exists (fun x -> if x == n then true else false) recenv then RECURSIVE
			       else begin let recenv = n::recenv in
					  let ret_type = type_exp n_props.fun_body env fenv tenv recenv in
			                  ( match n_props.fun_res with 
					    | None -> ret_type
					    | Some t -> let exp_type = (find t tenv) in
					      if ret_type != exp_type then begin
						print_terror (Apply (n, e_list)) ret_type exp_type "Function return type";
						raise TYPE_ERROR
					      end else exp_type) end
			       end
	| LetVarExp (v_list,e) -> type_exp e (type_vlist v_list env fenv tenv recenv) fenv tenv recenv
	| ArrayExp array_e -> let array_type = (find array_e.a_typ tenv)
			      and size_type = type_exp array_e.a_size env fenv tenv recenv 
			      and init_type = type_exp array_e.a_init env fenv tenv recenv in
			      let array_native_type = match array_type with 
				| ARRAY t -> t
				| NAME (_,r) -> ( match !r with | ARRAY t -> t 
								| _ -> raise TYPE_ENV_ERROR )
				| _ -> raise TYPE_ENV_ERROR in
			      if size_type != INT then begin
				print_terror array_e.a_size size_type INT "Array size";
				raise TYPE_ERROR
			      end else if init_type != array_native_type then begin
				print_terror array_e.a_init init_type array_native_type "Array init";
				raise TYPE_ERROR
			      end else array_type
	| RecordExp (f_e_list,typename) -> let rectype = (find typename tenv) in
					   let field_list = match rectype with
						| RECORD a -> a
						| NAME (_,r) -> ( match !r with | RECORD a -> a 
										| _ -> raise TYPE_ENV_ERROR )
						| _ -> raise TYPE_ENV_ERROR in
					   let rec z x = 
						let x_type = type_exp (snd x) env fenv tenv recenv in
						let y_type = snd(List.find (fun f -> if (fst f) = (fst x) then true else false) field_list) in
						if x_type != y_type && x_type != NIL && x_type != RECURSIVE then begin
							print_terror (snd x) x_type y_type "Record field";
							raise TYPE_ERROR
						end else ()
					   in List.iter z f_e_list;
					      rectype

and type_var var env fenv tenv recenv = match var with
	| SimpleVar v -> find v env
        | FieldVar (v,s) -> let get_record = type_var v env fenv tenv recenv in
			    let field_list = match get_record with | RECORD a -> a 
								   | NAME (_,r) -> ( match !r with | RECORD a -> a 
												   | _ -> raise TYPE_ENV_ERROR )
								   | _ -> raise TYPE_ENV_ERROR
			    in let rec get_field f = match f with
				| [] -> raise TYPE_ENV_ERROR
				| f::tail -> if (fst f) = s then (snd f)
					     else get_field tail
			    in get_field field_list
	| SubscriptVar (v,exp) -> let get_array = type_var v env fenv tenv recenv in
				  let array_native_type = match get_array with 
					| ARRAY t -> t
					| NAME (_,r) -> ( match !r with | ARRAY t -> t 
									| _ -> raise TYPE_ENV_ERROR )
					| _ -> raise TYPE_ENV_ERROR in
				  let sub_exp = type_exp exp env fenv tenv recenv in
				  if (sub_exp != INT) then begin
					print_terror exp sub_exp INT "SubscriptVar";
					raise TYPE_ERROR
				  end else array_native_type

and type_fundec fl env fenv tenv = match fl with
	| [] -> fenv
	| f::tail -> let fenv = add f.fun_id f fenv in
		     (* On vérifie le type à l'APPEL et pas à la DECLARATION !!!
		     (fun z -> match z with | Some t -> let env = fun_getenv f.fun_params env tenv in
							let ret_type = type_exp f.fun_body env fenv tenv in
							if ret_type != (find t tenv) then begin
								print_terror f.fun_body ret_type (find t tenv) "Function return type";
								raise TYPE_ERROR
							end else ()
					    | None -> ignore(type_exp f.fun_body (fun_getenv f.fun_params env tenv) fenv tenv)) f.fun_res;*)
		     type_fundec tail env fenv tenv

and fun_getenv p_list env tenv = match p_list with 
	| [] -> env
	| p::tail -> match p.p_typ with 
			| None -> fun_getenv tail (add p.p_name INT env) tenv
			| Some t -> fun_getenv tail (add p.p_name (find t tenv) env) tenv

and type_type tl env fenv tenv = 
	let ref_tenv = get_tenv tl [] tenv in
	let tenv = (snd ref_tenv) in
	let reflist = (fst ref_tenv) in
	let rec loop tl = match tl with
	| [] -> tenv
	| t::tail -> match (snd t) with
 			| Typ_record fl -> let own_ref = get_reflist reflist (fst t) in
					   let rec loop2 l = match l with
						| [] -> []
						| f::tail -> (f.fi_name,(find f.fi_typ tenv))::(loop2 tail)
					   in own_ref := RECORD (loop2 fl);
					   loop tail
			| _ -> loop tail 
	in loop tl

and check_reflist rl name = match rl with
	| [] -> false
	| (a,_)::b -> if a = name then true else check_reflist b name

and get_reflist tl name = match tl with
	| [] -> raise TYPE_ENV_ERROR
	| (a,r)::b -> if a = name then r else get_reflist b name 

and get_tenv tl reflist tenv = match tl with
	| [] -> (reflist, tenv)
	| t::tail -> match (snd t) with 
			| Typ_alias tname -> let make_ty = NAME ((fst t),ref (find tname tenv)) in
					     let tenv = add (fst t) make_ty tenv in
					     get_tenv tail reflist tenv
			| Typ_array tname -> let make_ty = (
						if tname = (fst t) then begin
							let rec own_ref = ref (ARRAY (NAME((fst t), own_ref))) in
							NAME ((fst t), own_ref)
						end else NAME ((fst t), ref (ARRAY (find tname tenv))) ) in
					        let tenv = add (fst t) make_ty tenv in
						get_tenv tail reflist tenv
			| Typ_record fl -> let own_ref = ref (RECORD []) in
					   let tenv = (add (fst t) (NAME ((fst t), own_ref)) tenv) in
					   let reflist = ((fst t), own_ref)::(reflist) in
					   get_tenv tail reflist tenv

and type_vlist vl env fenv tenv recenv =
	let rec loop vl env = match vl with
	| [] -> env
	| v::tail -> match v.var_typ with
			| None -> ( match v.var_init with | RecordExp _ -> let env = add v.var_id NIL env in loop tail env
							  | _ -> loop tail env )
			| Some t -> let env = add v.var_id (find t tenv) env in loop tail env
	in let env = loop vl env
	in match vl with
	| [] -> env
	| v::tail -> try let init_type = type_exp v.var_init env fenv tenv recenv in
			 match v.var_typ with
				| None -> if init_type == NIL then begin
						print_string ("[Var dec] type error : you must specify a type. ("^(string_of_symbol v.var_id)^")\n");
					        raise TYPE_ERROR
					  end else (let env = add v.var_id init_type env in
						    type_vlist tail env fenv tenv recenv)
				| Some t -> let foundenv = (find t tenv) in
					    if init_type == NIL && (match foundenv with | NAME (_,r) -> (match !r with | RECORD _ -> true | _ -> false) 
											| _ -> false) then begin
						(let env = add v.var_id foundenv env in
						 type_vlist tail env fenv tenv recenv)
					    end else if foundenv != init_type then begin
					        print_terror v.var_init init_type foundenv "Var decl";
					        raise TYPE_ERROR
					    end else (let env = add v.var_id foundenv env in
						      type_vlist tail env fenv tenv recenv)
		     with (CannotFind s) -> print_string ("[Var dec] type error : you must specify a type. ("^(string_of_symbol v.var_id)^" := , "^s^")\n");
					    raise TYPE_ERROR 
		      

let types ast quiet = if (type_exp ast (Symbol.mkempty()) (Symbol.mkempty()) (init_tenv())) []  = UNIT 
			then ast
		      else begin 
			if quiet = 0 then 
			  print_string ("/!\ Warning, program return type is not UNIT.\n") else ();
			ast end
