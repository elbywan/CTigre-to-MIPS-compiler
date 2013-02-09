
# Liste des fichiers a compiler, dans un ORDRE CORRECT pour le ocamlc final
SOURCES=symbol.mli symbol.ml \
	temp.mli temp.ml \
	label.mli label.ml \
	ast.mli \
	astPrint.mli astPrint.ml \
	parser.mli parser.ml \
	lexer.mli lexer.ml \
	ir.mli \
	irUtil.mli irUtil.ml \
	irPrint.mli irPrint.ml \
	irInterp.mli irInterp.ml \
	lin.mli \
	linPrint.mli linPrint.ml \
	canon.mli canon.ml \
	mipsAsm.mli \
	mipsAsmPrint.mli mipsAsmPrint.ml \
	PrettyPrint.mli PrettyPrint.ml \
	Leveloff.ml \
	main.ml

RESULT=ctigre

# Cible interessantes fournies par OCamlMakefile:
#  make (ou make bc) : compilation par defaut (en bytecode)
#  make clean : menage
#  make nc (ou native-code) : compilation en code natif
#  make dc (ou debug-code) : compilation avec -g pour ocamldebug
#  make top : compilation de ctigre.top, un toplevel caml contenant tout le code
#  make doc : creation automatique d'une documentation, par defaut uniquement
#             a partir des mli de $(SOURCES), cf $(DOC_FILES) sinon

all: bc


check: test   # au choix, make test ou make check pour lancer les tests

test: test-intir test-spim

test-intir: bc
	sh test-exec.sh -intir || true

# Pour l'instant, on fait les tests plutot avec spim (plus rapide)
test-spim: bc
	sh test-exec.sh -spim || true

# Possible aussi, mais lent !!
test-mars: bc
	sh test-exec.sh -mars

clean::
	for i in s S log; do rm -f TESTS/*.tg.$$i; done

include OCamlMakefile
