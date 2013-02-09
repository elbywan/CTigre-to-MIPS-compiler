open Printf
open PrettyPrint
open Typeur
open AstPrint
open Leveloff
open TradIr
open IrPrint
open IrInterp
open Ir
open Canon
open TradMips
open MipsAsmPrint
open AllocNaive

exception Erreur_de_syntaxe of int

(* compute AST *)

let _ =
   (* Project options *)
   let ast_flag = ref 0 in
   let attr_flag = ref 0 in
   let int_flag = ref 0 in
   let intir_flag = ref 0 in
   let lin_flag = ref 0 in
   let rawasm_flag = ref 0 in
   let asm_flag = ref 0 in
   (* Custom options *)
   let pretty_flag = ref 0 in
   let type_flag = ref 0 in
   let noesc_flag = ref 0 in
   let intirdeb_flag = ref 0 in
   let noopt_flag = ref 0 in
   let exclusive_flag = ref 0 in
   let help_flag = ref 0 in

   for i = 1 to Array.length Sys.argv - 1 do
	if Sys.argv.(i) = "-ast" then ast_flag := 1 else ();
	if Sys.argv.(i) = "-attr" then attr_flag := 1 else ();
	if Sys.argv.(i) = "-int" then int_flag := 1 else ();
	if Sys.argv.(i) = "-intir" then intir_flag := 1 else ();
	if Sys.argv.(i) = "-lin" then lin_flag := 1 else ();
	if Sys.argv.(i) = "-rawasm" then rawasm_flag := 1 else ();
	if Sys.argv.(i) = "-asm" then asm_flag := 1 else ();
	if Sys.argv.(i) = "-pretty" then pretty_flag := 1 else ();
	if Sys.argv.(i) = "-type" then type_flag := 1 else ();
	if Sys.argv.(i) = "-noesc" then noesc_flag := 1 else ();
	if Sys.argv.(i) = "-intirdeb" then intirdeb_flag := 1 else ();
	if Sys.argv.(i) = "-noopt" then noopt_flag := 1 else ();
	if Sys.argv.(i) = "-exclusive" then exclusive_flag := 1 else ();
	if Sys.argv.(i) = "-help" then help_flag := 1 else ();
   done;

   if (!help_flag = 1) || (Array.length Sys.argv = 1) then begin
	print_string("\nCTigre compilator - Help :\n\n");
	print_string("Usage : ctigre [OPTION,FILE]*\n");
	print_string("Example : ./ctigre -ast -attr TESTS/00_test.tg -noesc TESTS/01_calc.tg\n");
	print_string("\n");
	print_string("== Regular options : ==\n");
	print_string("-ast : prints raw syntax tree.\n");
	print_string("-attr : prints decorated syntax tree. (w/ level,offset and escape analysis)\n");
	print_string("-int : prints intermediate langage tree.\n");
	print_string("-intir : compiles program using intermediate langage.\n");
	print_string("-lin : prints linearized intermediate langage tree.\n");
	print_string("-rawasm : prints abstract assembler.\n");
	print_string("-asm : prints assembler with naive allocation.\n");
	print_string("== Custom options : ==\n");
	print_string("-intirdeb : same as -intir, with debug messages on.\n");
	print_string("-pretty : prints the CTigre representation of the raw tree using a pretty printer.\n");
	print_string("-type : enables type check.\n");
	print_string("-noesc : disables escape analysis.\n");
	print_string("-noopt : disables abstract assembler tile optimisations.\n");
	print_string("-exclusive : executes only the first option specified then exits.\n");
	print_string("-help : display this help.\n\n");
	exit(0);
   end else ();

   let excl_check () = if !exclusive_flag = 1 then exit(0) else () in

   for i = 1 to Array.length Sys.argv - 1 do
	if (String.get Sys.argv.(i) 0) != '-' then begin
		let chan_in = open_in Sys.argv.(i) in
		let lexbuf = Lexing.from_channel chan_in in
		try 
			let ast = ( if !type_flag = 1 then  
				       Typeur.types (Parser.programme Lexer.token lexbuf) 1
				    else Parser.programme Lexer.token lexbuf ) in 
			if !pretty_flag = 1 then begin PrettyPrint.print ast; excl_check() end else ();
			if !ast_flag = 1 then begin AstPrint.print_raw ast; excl_check() end else ();
			let attr = if !noesc_flag = 1 then Leveloff.level ast 0 else Leveloff.level ast 1 in
			if !attr_flag = 1 then begin AstPrint.print_attr attr; excl_check() end else ();
			let ir = ir_trad attr in
			if !int_flag = 1 then begin print ir; excl_check() end else ();
			if !intir_flag = 1 then begin interp ir false; excl_check() end else ();
			if !intirdeb_flag = 1 then begin interp ir true; excl_check() end else ();
			let linear = { strings = ir.strings;
				       procs = (let rec getprocs procs = match procs with 
					          | [] -> []
					          | p::tail -> { p with code = (let l = linearize p.code
										in ((traceSchedule (basicBlocks (fst l))),snd l)) }::(getprocs tail)
					        in getprocs ir.procs) } in
			if !lin_flag = 1 then begin LinPrint.print linear; excl_check() end else ();
			let abstr = tradAbstr linear !noopt_flag in
			if !rawasm_flag = 1 then begin (print_asm print_abstr_reg abstr); excl_check() end else ();
			let naive = alloc_n abstr in
			if !asm_flag = 1 then begin (print_asm print_simpl_reg naive); excl_check() end else ();
		( close_in chan_in );
		with Parsing.Parse_error -> ( close_in chan_in );
		     raise (Erreur_de_syntaxe(Lexing.lexeme_start lexbuf));
	end else ()
   done



