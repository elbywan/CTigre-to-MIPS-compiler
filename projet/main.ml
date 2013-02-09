open Printf
open PrettyPrint
open AstPrint
open Leveloff

exception Erreur_de_syntaxe of int

(* compute AST *)

let _ =

   printf("\n");

   if (Array.length Sys.argv) > 1 && Sys.argv.(1) = "-ast" then begin
	for i = 2 to Array.length Sys.argv - 1 do
	let chan_in = open_in Sys.argv.(i) in
	let lexbuf = Lexing.from_channel chan_in in
	try 
		let ast = Parser.programme Lexer.token lexbuf in
		print_raw ast; 
		print_string("\n\n");
		( close_in chan_in ); ast
	with Parsing.Parse_error ->
             ( close_in chan_in );
             raise (Erreur_de_syntaxe(Lexing.lexeme_start lexbuf));
	done

   end else begin
	for i = 1 to Array.length Sys.argv - 1 do
	let chan_in = open_in Sys.argv.(i) in
	let lexbuf = Lexing.from_channel chan_in in
	try 
		let ast = Parser.programme Lexer.token lexbuf in
		(** PrettyPrint.print ast; **) 
		AstPrint.print_attr (Leveloff.level ast);
		print_string("\n\n");
		( close_in chan_in ); ast
	with Parsing.Parse_error ->
             ( close_in chan_in );
             raise (Erreur_de_syntaxe(Lexing.lexeme_start lexbuf));
	done
   end



