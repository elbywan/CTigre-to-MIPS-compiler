open Ast
open Ir
open Label
open Temp
open Symbol

(* For testing purposes. *)
let rec print_stringcount c = 
	let _ = print_string("[") in
	let rec loop c = match c with
	| [] -> ()
	| a::b -> print_string("("); print_string (string_of_label (fst a)); 
		  print_string(","); print_string (snd a); print_string(")");
		  loop b
	in let _ = loop c in
	print_string("]");

and count_str = ref []

and proc_list = ref []

and check_op o = match o with
	| PlusOp -> true | MinusOp -> true | TimesOp -> true | DivideOp -> true
	| AndOp ->  true | OrOp -> true
	| EqOp -> false | NeqOp -> false | LtOp -> false | LeOp -> false | GtOp -> false | GeOp -> false

and get_binop o = match o with
	| PlusOp -> PLUS | MinusOp -> MINUS | TimesOp -> MUL | DivideOp -> DIV
	| AndOp ->  AND | OrOp -> OR
	| EqOp -> assert false | NeqOp -> assert false | LtOp -> assert false | LeOp -> assert false | GtOp -> assert false | GeOp -> assert false

and get_relop o = match o with
	| PlusOp -> assert false | MinusOp -> assert false | TimesOp -> assert false | DivideOp -> assert false
	| AndOp ->  assert false | OrOp -> assert false
	| EqOp -> EQ | NeqOp -> NE | LtOp -> LT | LeOp -> LE | GtOp -> GT | GeOp -> GE

and get_slink l_courant l_recherche = 
	if l_recherche > l_courant then assert false
	else if l_recherche < l_courant then MEM (get_slink l_courant (l_recherche+1))
	else FP

and get_slink_fun l_courant l_recherche = 
	if l_recherche > (l_courant+1) then assert false
	else if l_recherche = (l_courant + 1) then FP
	else if l_recherche < l_courant then MEM (get_slink_fun l_courant (l_recherche+1))
	else MEM(FP)

and make_ir exp fun_label fun_name old_fenv old_recenv fun_args l =
	let fun_esc = ref 0 in
	let rec ir_exp exp fenv recenv l = match exp with
	| NilExp -> CONST 0
	| IntExp i -> CONST i
	| StringExp s -> let lab = new_label "str" in
			 let _ = count_str := (lab, s)::!count_str in
			 STR lab
	| CharExp c ->   CONST (Char.code c)
			 (* Obsolète : codage des caractères comme chaînes. 
			 let lab = new_label "char" in
			 let _ = count_str := (lab, (Char.escaped c))::!count_str in
			 STR lab *)
	| Opexp (op,e1,e2) -> if check_op op then 
				   let binop = get_binop op in
				   let result binop = match binop with
				        | AND -> let lab0 = new_label "opand1" in
						 let lab0_bis = new_label "opand1bis" in
						 let lab1 = new_label "opand2" in
						 let lab2 = new_label "opand3" in
						 let return_val = new_temp() in 
						 ESEQ([CJUMP(EQ,ir_exp e1 fenv recenv l, CONST 1, lab0, lab1);
						       LABEL lab0;
						       CJUMP(EQ,ir_exp e2 fenv recenv l, CONST 1, lab0_bis, lab1);
						       LABEL lab0_bis;
						       MOVE(TEMP return_val,CONST 1);
						       JUMP lab2;
						       LABEL lab1;
						       MOVE(TEMP return_val,CONST 0);
						       LABEL lab2], TEMP return_val)
					| OR ->  let lab0 = new_label "opor1" in
						 let lab0_bis = new_label "opor1bis" in
						 let lab1 = new_label "opor2" in
						 let lab2 = new_label "opor3" in
						 let return_val = new_temp() in 
						 ESEQ([CJUMP(EQ,ir_exp e1 fenv recenv l, CONST 0, lab0, lab1);
						       LABEL lab0;
						       CJUMP(EQ,ir_exp e2 fenv recenv l, CONST 0, lab0_bis, lab1);
						       LABEL lab0_bis;
						       MOVE(TEMP return_val,CONST 0);
						       JUMP lab2;
						       LABEL lab1;
						       MOVE(TEMP return_val,CONST 1);
						       LABEL lab2], TEMP return_val)
					| _ -> BINOP(binop,ir_exp e1 fenv recenv l,ir_exp e2 fenv recenv l)
				   in result binop
			      else let relop = get_relop op in
				   let lab0 = new_label "op1" in
				   let lab1 = new_label "op2" in
				   let lab2 = new_label "op3" in
				   let return_val = new_temp() in
				   ESEQ([CJUMP(relop,ir_exp e1 fenv recenv l, ir_exp e2 fenv recenv l, lab0, lab1);
					 LABEL lab0;
					 MOVE(TEMP return_val,CONST 1);
					 JUMP lab2;
					 LABEL lab1;
					 MOVE(TEMP return_val,CONST 0);
					 LABEL lab2], TEMP return_val)
	| VarExp v -> ir_var v fenv recenv l
	| AssignExp (var,e) ->  ESEQ([MOVE(ir_var var fenv recenv l, ir_exp e fenv recenv l)],CONST 0)
	| LetVarExp (v_list,e) -> ESEQ(ir_vlist v_list fenv recenv l, ir_exp e fenv recenv l)
	| LetFunExp (funlist,e) -> let newfenv = ir_funlist funlist fenv recenv l
				   in ir_exp e newfenv recenv l
	| TypeExp (typelist,e) -> let newrecenv = ir_typel typelist fenv recenv l
				  in ir_exp e fenv newrecenv l
	| Apply (n, e_list) -> let fcall n = match n with 
			       | Internal f -> let f_lab = find f.f_name fenv in
					       let ls = get_slink_fun l f.f_level in
					       let rec reclist e_list = match e_list with
					       | [] -> [] | a::b -> (ir_exp a fenv recenv l)::(reclist b)
					       in let explist = reclist e_list in
					       CALL(f_lab,ls::explist)
			       | Predefined lab -> let rec reclist e_list = match e_list with
					         | [] -> [] | a::b -> (ir_exp a fenv recenv l)::(reclist b)
					         in let explist = reclist e_list in
					         CALL(lab,explist)
			       in fcall n
	| SeqExp (e,e2) -> ESEQ ([ EXP (ir_exp e fenv recenv l) ], ir_exp e2 fenv recenv l)
	| IfExp (eif,ethen,eelse) -> let if_ok = new_label "if_ok" in
				     let if_nok = new_label "of_notok" in
				     let if_cont = new_label "if_cont" in
				     let return_val = new_temp() in
				     let match_else eelse = match eelse with
				     | None ->
				       ESEQ([ CJUMP(EQ,ir_exp eif fenv recenv l,CONST 1,if_ok,if_nok);
					      LABEL if_ok;
					      EXP(ir_exp ethen fenv recenv l);
					      JUMP if_cont;
					      LABEL if_nok;
					      LABEL if_cont;
					    ],CONST 0)
				     | Some e -> 
				       ESEQ([ CJUMP(EQ,ir_exp eif fenv recenv l,CONST 1,if_ok,if_nok);
					      LABEL if_ok;
					      MOVE(TEMP return_val, ir_exp ethen fenv recenv l);
					      JUMP if_cont;
					      LABEL if_nok;
					      MOVE(TEMP return_val, ir_exp e fenv recenv l);
					      LABEL if_cont;
					    ],TEMP return_val)
					in match_else eelse
	| WhileExp (ewhile,edo) -> let lab_check = new_label "while_check" in
				   let lab_do = new_label "while_do" in
				   let lab_done = new_label "while_done" in
				   ESEQ([LABEL lab_check; 
					 CJUMP (EQ,ir_exp ewhile fenv recenv l,CONST 1,lab_do,lab_done);
					 LABEL lab_do;
					 EXP (ir_exp edo fenv recenv l);
					 JUMP lab_check;
					 LABEL lab_done],CONST 0)
	| ForExp f -> let for_check = new_label "for_check"
		      and for_do = new_label "for_do" 
		      and for_done = new_label "for_done" 
		      and dir = match f.for_dir with | Up -> LE | Down -> GE 
		      and add_sign = match f.for_dir with | Up -> PLUS | Down -> MINUS 
		      and exp_to_check = ir_exp f.for_hi fenv recenv l
		      and temp_to_check = new_temp()
		      and get_var = ir_var (SimpleVar f.for_var) fenv recenv l 
		      and _ = match f.for_var.v_pos  with | Temp _ -> () | Stack _ -> fun_esc := (!fun_esc + 1)
		      and get_init = ir_exp f.for_lo fenv recenv l in 
		      ESEQ([ MOVE(get_var,get_init);
			     MOVE(TEMP temp_to_check,exp_to_check);
			     LABEL for_check;
			     CJUMP (dir,get_var,TEMP temp_to_check,for_do,for_done);
			     LABEL for_do;
			     EXP (ir_exp f.for_body fenv recenv l);
			     MOVE(get_var,BINOP(add_sign,get_var,CONST 1));
			     JUMP for_check;
			     LABEL for_done
			   ],CONST 0)
	| ArrayExp array_e -> ir_array array_e fenv recenv l
	| RecordExp (f_e_list,typename) -> ir_record f_e_list fenv recenv l

	and ir_var v fenv recenv l = match v with
	| SimpleVar v -> let result = match v.v_pos with
			 | Stack (lev, off) -> MEM(BINOP(MINUS, get_slink l lev, WORDMUL(CONST (off))))
			 | Temp t -> TEMP t
			 in result
	| FieldVar (v,s) -> MEM(BINOP(PLUS,ir_var v fenv recenv l,WORDMUL (CONST (find s recenv))))
	| SubscriptVar (v,exp) -> MEM(BINOP(PLUS, (ir_var v fenv recenv l), WORDMUL(ir_exp exp fenv recenv l)))

	and ir_vlist vl fenv recenv l = 
		let rec alloc_rec vl = match vl with 
		| [] -> []
		| vh::vt -> let find_it = ir_var (SimpleVar vh.var_id) fenv recenv l in
			    match vh.var_init with 
				| RecordExp (vlist,e) -> (MOVE(find_it, CALL(malloc,[BINOP(MUL,WORDMUL(CONST (List.length vlist)),CONST 1)])))::(alloc_rec vt)
				| _ -> alloc_rec vt
		in let starting_instr = alloc_rec vl 
		in let rec regular_loop vl = match vl with
		| [] -> []
		| vh::vt -> let _ = match vh.var_id.v_pos  with | Temp _ -> () | Stack _ -> fun_esc := (!fun_esc + 1) in
			let find_it = ir_var (SimpleVar vh.var_id) fenv recenv l in
			match vh.var_init with 
				| RecordExp (vlist,e) -> let rec get_list li = match li with
							| [] -> []
							| rh::rt -> let count = (find (fst rh) recenv) in
								(MOVE(MEM(BINOP(PLUS, find_it, WORDMUL(CONST count))),ir_exp (snd rh) fenv recenv l))::(get_list rt)
							in let instr_l = get_list vlist
							in (MOVE(find_it,ESEQ(instr_l,find_it)))::(regular_loop vt)
				| _ -> (MOVE(find_it,ir_exp vh.var_init fenv recenv l))::(regular_loop vt)
		in starting_instr@(regular_loop vl)

	and ir_funlist fl fenv recenv l = 
		let rec get_fenv fl fenv = match fl with
		| [] -> fenv
		| fh::ft -> let f_label = (new_label (string_of_symbol fh.fun_id.f_name)) in
			    get_fenv ft (add fh.fun_id.f_name f_label fenv)
		in let rec funrec fl fenv recenv l = match fl with 
		| [] -> fenv
		| fh::ft -> make_ir fh.fun_body (find fh.fun_id.f_name fenv) fh.fun_id.f_name fenv recenv (1+(List.length fh.fun_params)) (l+1);
			    (funrec ft fenv recenv l) 
		in funrec fl (get_fenv fl fenv) recenv l

	and ir_array arr fenv recenv l = 
		let array_check = new_label "array_check" in
		let array_do = new_label "array_do" in
		let array_done = new_label "array_done" in
		let i = new_temp() in
		let p = new_temp() in
		ESEQ([MOVE(TEMP i, ir_exp arr.a_size fenv recenv l);
		      MOVE(TEMP p, CALL(malloc,[BINOP(MUL,WORDMUL(TEMP i),CONST 1)]));
		      LABEL array_check; 
		      MOVE(TEMP i,BINOP(MINUS,TEMP i,CONST 1));
		      CJUMP (GE,TEMP i,CONST 0,array_do,array_done);
		      LABEL array_do;
		      MOVE (MEM(BINOP(PLUS,TEMP p,WORDMUL(TEMP i))),ir_exp arr.a_init fenv recenv l);
		      JUMP array_check;
		      LABEL array_done],TEMP p)

	and ir_record rl fenv recenv l  = 
		let p = new_temp() in
		let length = (List.length rl) in
		let rec get_list li = match li with
		| [] -> []
		| rh::rt -> let count = (find (fst rh) recenv) in 
			    (MOVE(MEM(BINOP(PLUS, TEMP p, WORDMUL(CONST count))),ir_exp (snd rh) fenv recenv l))::(get_list rt)
		in let alloc = MOVE(TEMP p, CALL(malloc,[BINOP(MUL,WORDMUL(CONST length),CONST 1)]))
		in let instr_l = alloc::(get_list rl)
		in ESEQ(instr_l,TEMP p) 

	and ir_typel typelist fenv recenv l = match typelist with
	| [] -> recenv
	| th::tt -> match (snd th) with
			| Typ_record t -> let rec count t c recenv = match t with 
					  | [] -> recenv
					  | t1::t2 -> let newrecenv = (add t1.fi_name c recenv)
						      in count t2 (c+1) newrecenv
					  in let newrec = (count t 0 recenv) in
					  ir_typel tt fenv newrec l 
			| _ -> ir_typel tt fenv recenv l

	in let c = ir_exp exp (add fun_name fun_label old_fenv) old_recenv l in
	(* Test d'échappement des variables
	print_string("function  : "); print_string(Label.string_of_label fun_label); 
	print_string(" "); print_int(!fun_esc); print_string("\n"); *)
	proc_list := { entry = fun_label;   
		       numargs = fun_args; 
		       numvars = !fun_esc; 
		       code = c
		     }::(!proc_list)


and mainwrapper exp  =
	LetFunExp ([{ fun_id = { f_name = (symbol "main") ; f_level = 1 } ;
		      fun_params = [];
		      fun_res = Some (symbol "int") ;
		      fun_body = SeqExp ( exp , IntExp (0))}] ,
		      Apply (Internal  { f_name = (symbol "main") ; f_level = 1 }, []))

and ir_trad aexp = let _ = (make_ir aexp Label.main (symbol "main") (mkempty()) (mkempty()) 0 1) in
		   { strings = !count_str; 
		     procs = !proc_list } 