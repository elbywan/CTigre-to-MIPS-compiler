open MipsAsm
open Lin
open Ir
open Label

exception SYNTAX_FAILURE of Lin.exp
exception OP_FAILURE
exception MEM_FAILURE

let rec wordsize = 4 
and fifo = ref [] 
and resetfifo () = 
  fifo := [] 
and addfifo elem = 
  fifo := elem::(!fifo) 
and addfifol elem_list = match elem_list with
  | [] -> ()
  | a::b -> addfifo a; addfifol b 

and opt_flag = ref 0

and simplify_binop bin = match bin with
	| LBINOP (op, LCONST a, LCONST b) -> ( match op with | PLUS -> LCONST (a+b)
							     | MINUS -> LCONST (a-b)
							     | MUL -> LCONST (a*b)
							     | DIV -> LCONST (a/b) 
							     | _ -> bin )
	| LBINOP (op, LCONST a, LBINOP (o,i,j)) -> can_binsimplify (LBINOP (op, LCONST a, (simplify_binop (LBINOP (o,i,j)))))
	| LBINOP (op, LBINOP (o,i,j), LCONST b) -> can_binsimplify (LBINOP (op, (simplify_binop (LBINOP (o,i,j))), LCONST b))
	| LBINOP (op, LBINOP (o,i,j), LBINOP (o2,i2,j2)) -> can_binsimplify (LBINOP (op, (simplify_binop (LBINOP (o,i,j))), (simplify_binop (LBINOP (o2,i2,j2)))))
	| _ -> bin

and can_binsimplify bin = match bin with
	| LBINOP (op, LCONST a, LCONST b) -> simplify_binop (LBINOP (op, LCONST a, LCONST b)) 
	| _ -> bin

and simplify_wordmul word = match word with
	| LWORDMUL (LCONST i) -> LCONST (i*wordsize)
	| _ -> word

and maxMunch_exp exp t = match exp with
  | LBINOP (op,e1,e2) -> OP (op, Rtmp t, maxMunch_checktemp e1, maxMunch_checktemp e2)
  | LMEM (LBINOP (op,e,LWORDMUL (LCONST i))) -> (match op with | PLUS -> LW (Rtmp t, wordsize*i, maxMunch_checktemp e)
							       | MINUS -> LW (Rtmp t, -(wordsize*i), maxMunch_checktemp e)
							       | _ -> raise OP_FAILURE)
  | LMEM (LBINOP (op,e,LWORDMUL (LTEMP te))) -> LW (Rtmp t, 0, maxMunch_checktemp (LBINOP (op, LBINOP(MUL, LCONST wordsize, LTEMP te), e)))
  | LMEM (LBINOP (op,e,LWORDMUL z)) ->  let newtemp = match (maxMunch_checktemp z) with | Rtmp t -> t | _ -> raise MEM_FAILURE in
					LW (Rtmp t, 0, maxMunch_checktemp (LBINOP (op, LBINOP(MUL, LCONST wordsize, LTEMP newtemp), e)))
  | LMEM e -> (match e with | LFP -> LW (Rtmp t, 0, Rfp)
			    | LMEM _ -> LW (Rtmp t, 0, maxMunch_checktemp e)
			    | _ -> raise MEM_FAILURE)
  | LCONST i -> LI (Rtmp t, i)
  | LSTR lbl -> LA (Rtmp t, lbl)
  | LWORDMUL (LCONST i) -> LI (Rtmp t, wordsize*i)
  | LWORDMUL e -> OPI (MUL, Rtmp t, maxMunch_checktemp e,wordsize)
  | _ -> raise (SYNTAX_FAILURE exp)

and maxMunch_checktemp exp = match exp with
  | LTEMP t -> Rtmp t
  | LFP -> Rfp
  | z -> let t = Temp.new_temp () in
	 if !opt_flag = 0 then begin
		let z = simplify_binop z in
		let z = simplify_wordmul z in
		addfifo (maxMunch_exp z t); Rtmp t
	 end else begin addfifo (maxMunch_exp z t); Rtmp t end

and maxMunch_stm stm = match stm with
  | LLABEL lbl -> addfifo (LBL lbl)
  | LJUMP lbl -> addfifo (J lbl)
  | LCJUMP (op,exp1,exp2,lbl,_) -> addfifo (BR (op, maxMunch_checktemp exp1, maxMunch_checktemp exp2, lbl))
  | LMOVETEMP (temp,exp) -> addfifo (MOV (Rtmp temp, maxMunch_checktemp exp))
  | LMOVEMEM (exp1,exp2) -> addfifo (SW (maxMunch_checktemp exp2, 0, maxMunch_checktemp exp1))
  | LMOVETEMPCALL (temp,lbl,exp_list) -> let rec movargs args count = match args with
					   | [] -> []
					   | arg::t -> (SW (maxMunch_checktemp arg, wordsize * count, Rsp))::(movargs t (count+1))
					 in let args = movargs exp_list 0 in
					 addfifol(
					 ((OPI (MINUS, Rsp, Rsp, (List.length exp_list) * wordsize))::(args))@[
					   JAL lbl;
					   MOV (Rtmp temp, Rres);
					   OPI (PLUS, Rsp, Rsp, (List.length exp_list) * wordsize)])
  | LEXPCALL (lbl,exp_list) -> let rec movargs args count = match args with
				 | [] -> []
				 | arg::t -> (SW (maxMunch_checktemp arg, wordsize * count, Rsp))::(movargs t (count+1))
			       in let args = movargs exp_list 0 in
			       addfifol(
			       ((OPI (MINUS, Rsp, Rsp, (List.length exp_list) * wordsize))::(args))@[
				 JAL lbl;
				 OPI (PLUS, Rsp, Rsp, (List.length exp_list) * wordsize)] )


and maxMunch_funbody f check = 
	resetfifo ();
	let rec loop z = match z with 
		| [] -> if check = false then addfifo (MOV (Rres, maxMunch_checktemp (snd f))) else ()
		| h::t -> (maxMunch_stm h); (loop t)
	in loop (fst f); (List.rev !fifo)

and tradAbstr lin opt = opt_flag := opt;
			{ strings = lin.strings;
		          procs = (let rec getprocs procs check = match procs with 
				   | [] -> []
				   | p::tail -> if check = false then begin
						{ p with code = (* Pas de prologue / épilogue pour l'assembleur abstrait.
								[ OPI (MINUS, Rsp, Rsp, wordsize*(p.numvars+2));
								  SW (Rfp, wordsize * 2, Rsp);
								  SW (Rra, wordsize * 1, Rsp);
								  OPI (PLUS, Rfp, Rsp, wordsize*(p.numvars+2)); 
								]@*)(maxMunch_funbody p.code false)(*@[
								  LW (Rfp, wordsize * 2, Rsp);
								  LW (Rra, wordsize * 1, Rsp);
								  OPI (PLUS, Rsp, Rsp, wordsize*(p.numvars+2)); 
								  JR Rra ]*) }::(getprocs tail false)
						end else begin
						{ p with code = (*[ OPI (MINUS, Rsp, Rsp, wordsize*p.numvars);
								]@*)(maxMunch_funbody p.code true)(*@[
								OPI (PLUS, Rsp, Rsp, wordsize*p.numvars); JAL Label.exit ]*) }::(getprocs tail false)
						end
			          in getprocs lin.procs true) }