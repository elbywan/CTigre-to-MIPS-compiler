type token =
  | AND
  | ARRAY
  | ASSIGNS
  | BEGIN
  | COLON
  | COMMA
  | DIV
  | DO
  | DONE
  | DOWNTO
  | DOT
  | ELSE
  | END
  | EOF
  | EQUALS
  | FOR
  | IDENT of (string)
  | IF
  | IN
  | LCURL
  | FUNCTION
  | VAR
  | ANDLET
  | LPAR
  | LSQ
  | MINUS
  | MULT
  | NIL
  | GTEQ
  | LTEQ
  | GT
  | LT
  | NE
  | OR
  | NUM of (int)
  | OF
  | PLUS
  | RCURL
  | RPAR
  | RSQ
  | CHAR of (char)
  | SEMICOLON
  | STRING of (string)
  | TO
  | THEN
  | TYPE
  | WHILE

val programme :
  (Lexing.lexbuf  -> token) -> Lexing.lexbuf -> Ast.rawexp
