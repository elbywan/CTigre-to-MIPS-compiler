open MipsAsm
open Ir

exception TMP_ERROR

let rec abstr_to_naive reg = match reg with
	| Rsp -> Nsp
	| Rfp -> Nfp
	| Rra -> Nra
	| Rres -> Nres
	| Rtmp tmp -> raise TMP_ERROR

and wordsize = 4 

and naive_ilist ilist = 
	let env = ref []
	in let rec check_instr ?(count = 1) e l = match l with
		| [] -> env := !env@[e]; -(count*wordsize)
		| a::b -> if a = e then -(count*wordsize) else check_instr ~count:(count+1) e b
	in let naive_instr instr = match instr with 
		(* Cas "spéciaux" (exhaustif) *)
		| OPI (op,Rsp,Rsp,i) -> [ OPI (op,Nsp,Nsp,i) ]
		| OPI (op,Rfp,Rfp,i) -> [ OPI (op,Nfp,Nfp,i) ]
		| OPI (op,Rsp,Rfp,i) -> [ OPI (op,Nsp,Nfp,i) ]
		| OPI (op,Rfp,Rsp,i) -> [ OPI (op,Nfp,Nsp,i) ]
		| OP (op,rdest,Rfp,r2) -> let check_r2 = check_instr r2 !env
					  and check_dest = check_instr rdest !env in
					  [ LW (Nsrc2, check_r2, Nfp);
					    OP (op, Ndst, Nfp, Nsrc2);
					    SW (Ndst, check_dest, Nfp) ]
		| OP (op,rdest,r1,Rfp) -> let check_r1 = check_instr r1 !env
					  and check_dest = check_instr rdest !env in
					  [ LW (Nsrc1, check_r1, Nfp);
					    OP (op, Ndst, Nfp, Nsrc1);
					    SW (Ndst, check_dest, Nfp) ]
		| OP (op,rdest,Rsp,r2) -> let check_r2 = check_instr r2 !env
					  and check_dest = check_instr rdest !env in
					  [ LW (Nsrc2, check_r2, Nsp);
					    OP (op, Ndst, Nsp, Nsrc2);
					    SW (Ndst, check_dest, Nsp) ]
		| OP (op,rdest,r1,Rsp) -> let check_r1 = check_instr r1 !env
					  and check_dest = check_instr rdest !env in
					  [ LW (Nsrc1, check_r1, Nsp);
					    OP (op, Ndst, Nsp, Nsrc1);
					    SW (Ndst, check_dest, Nsp) ]
		| SW (Rfp, i, Rsp) -> [ SW (Nfp, i, Nsp) ]
		| SW (Rra, i, Rsp) -> [ SW (Nra, i, Nsp) ]
		| LW (Rfp, i, Rsp) -> [ LW (Nfp, i, Nsp) ]
		| LW (Rra, i, Rsp) -> [ LW (Nra, i, Nsp) ]
		| MOV (Rfp, Rsp) -> [ MOV (Nfp, Nsp) ]
		| MOV (Rsp, Rfp) -> [ MOV (Nsp, Nfp) ]
		| MOV (rdest, Rres) -> let check_dest = check_instr rdest !env in
				       [ SW (Nres, check_dest, Nfp) ]
		| MOV (Rres, rsource) -> let check_src = check_instr rsource !env in
					 [ LW (Nres, check_src, Nfp) ]
		| MOV (rdest, Rfp) -> let check_dest = check_instr rdest !env in
				       [ SW (Nfp, check_dest, Nfp) ]
		| MOV (Rfp, rsource) -> let check_src = check_instr rsource !env in
					 [ LW (Nfp, check_src, Nfp) ]
		| MOV (rdest, Rsp) -> let check_dest = check_instr rdest !env in
				       [ SW (Nsp, check_dest, Nsp) ]
		| MOV (Rsp, rsource) -> let check_src = check_instr rsource !env in
					 [ LW (Nsp, check_src, Nsp) ]
		(* Cas "normaux" *)
		| OP (op,rdest,r1,r2) -> let check_r1 = check_instr r1 !env 
					 and check_r2 = check_instr r2 !env
					 and check_dest = check_instr rdest !env in
					 [ LW (Nsrc1, check_r1, Nfp);
					   LW (Nsrc2, check_r2, Nfp);
					   OP (op, Ndst, Nsrc1, Nsrc2);
					   SW (Ndst, check_dest, Nfp) ]
		| OPI (op,rdest,reg,i) -> let check_reg = check_instr reg !env
					  and check_dest = check_instr rdest !env in
					  [ LW (Nsrc1, check_reg, Nfp);
					    OPI (op, Ndst, Nsrc1, i);
					    SW (Ndst, check_dest, Nfp) ]
		| BR (op,r1,r2,lbl) ->  let check_r1 = check_instr r1 !env 
					and check_r2 = check_instr r2 !env  in
					[ LW (Nsrc1, check_r1, Nfp);
					  LW (Nsrc2, check_r2, Nfp);
					  BR (op, Nsrc1, Nsrc2, lbl) ]
		| BRI (op,reg,i,lbl) -> let check_reg = check_instr reg !env in
					[ LW (Nsrc1, check_reg, Nfp);
					  BRI (op, Nsrc1, i, lbl) ]
		| LW (rdest,i,Rtmp t) -> let check_reg = check_instr (Rtmp t) !env
					 and check_dest = check_instr rdest !env in
					 [ LW (Nsrc1, check_reg, Nfp);
					   LW (Ndst, i, Nsrc1);
					   SW (Ndst, check_dest, Nfp) ]
		| LW (rdest,i,rmem) -> let check_dest = check_instr rdest !env in
				       [ LW (Ndst, i, (abstr_to_naive rmem));
					 SW (Ndst, check_dest, Nfp) ]
		| SW (rsource, i, Rtmp t) -> let check_reg = check_instr (Rtmp t) !env
					     and check_src = check_instr rsource !env in
					     [ LW (Nsrc1, check_src, Nfp);
					       LW (Ndst, check_reg, Nfp);
					       SW (Nsrc1, i, Ndst) ]
		| SW (rsource, i, rmem) -> let check_src = check_instr rsource !env in
					   [ LW (Ndst, check_src, Nfp);
					     SW (Ndst, i, (abstr_to_naive rmem)) ]
		| LA (rdest, lbl) -> let check_dest = check_instr rdest !env in
				     [ LA (Ndst, lbl);
				       SW (Ndst, check_dest, Nfp) ]
		| LI (rdest, i) -> let check_dest = check_instr rdest !env in
				   [ LI (Ndst, i);
				     SW (Ndst, check_dest, Nfp) ]
		| MOV (rdest, rsource) -> let check_dest = check_instr rdest !env 
					  and check_src = check_instr rsource !env in
					  [ LW (Ndst, check_src, Nfp);
					    SW (Ndst, check_dest, Nfp) ]
		| J lbl -> [J lbl]
		| JAL lbl -> [JAL lbl]
		| JR rmem -> [JR (abstr_to_naive rmem)]
		| LBL lbl -> [LBL lbl]
		| COMM s -> [COMM s]
	in let rec loop i = 
		match i with
		| [] -> []
		| instr::tail -> let newinstr = naive_instr instr in
				 newinstr@(loop tail)
	in let instr_list = loop ilist 
        in (instr_list,!env)

and alloc_n mips = { strings = mips.strings;
		     procs = (let rec getprocs procs check = match procs with 
				   | [] -> []
				   | p::tail -> let proc = naive_ilist p.code in
						let maxtemp = List.length (snd proc) in
						if check = false then begin
							{ p with numvars = maxtemp;
							  code = [ OPI (MINUS, Nsp, Nsp, wordsize*(maxtemp+2));
								   SW (Nfp, wordsize * 1, Nsp);
								   SW (Nra, 0, Nsp);
								   OPI (PLUS, Nfp, Nsp, wordsize*(maxtemp+2)); 
								 ]@(fst proc)@[
								   LW (Nfp, wordsize * 1, Nsp);
								   LW (Nra, 0, Nsp);
								   OPI (PLUS, Nsp, Nsp, wordsize*(maxtemp+2)); 
								   JR Nra ] }::(getprocs tail false)
						end else begin
							{ p with numvars = maxtemp;
							  code = [MOV (Nfp, Nsp); 
								  OPI (MINUS, Nsp, Nsp, wordsize*maxtemp);
								 ]@(fst proc)@[
								   OPI (PLUS, Nsp, Nsp, wordsize*maxtemp);
								   JAL Label.exit ] }::(getprocs tail false)
						end
			      in getprocs mips.procs true)
		 }

