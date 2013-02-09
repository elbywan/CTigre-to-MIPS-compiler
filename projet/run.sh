#!/bin/sh

usage() {
    echo "`basename $0` [-color] [-intir|-mars|-spim|-qemu|-x86] [ctigre] file.tg"
}

ctigredir=`dirname $0`

asm_flags=
interp=-spim
loop=true
while [ "$loop" = "true" ]; do
  case "$1" in
    -help|--help) 
	   usage
           exit;;
    -intir|-mars|-spim|-qemu|-x86) 
           interp=$1
           shift;;
    -*)
           asm_flags="$asm_flags $1"
           shift;;
    *) loop=false;;
  esac
done

case $asm_flags in
    *-color*) ;;
    *-asm*);;
    *) asm_flags="$asm_flags -asm";;
esac

ctigre=$ctigredir/ctigre
if [ "$2" != "" ]; then
    ctigre=$1
    shift
fi

file=$1

case $interp in
    -intir) $ctigre -intir $file;;
    -spim) $ctigre $asm_flags $file > $file.s
	  cat $ctigredir/runtime.s >> $file.s
	  spim -file $file.s | tail -n +6
	  echo;;
    -mars) $ctigre $asm_flags $file > $file.s
          cat $ctigredir/runtime.s >> $file.s
          mars $file.s;;
    -qemu)
	echo "#include \"runtime.s\"" > $file.S
	$ctigre $asm_flags $file >> $file.S
	../realasm/cross/as-ctigre -o $file.bin $file.S
	qemu-mips $file.bin
	echo;;
    -x86) 
	case $asm_flags in
	   *-color*)
	       echo "Error: x86 generator incompatible with graph coloring"
	       exit 1;;
	esac
        $ctigre -intel $file > $file.S
        ../realasm/x86/as-ctigre -o $file.bin $file.S
        $file.bin
	echo;;
esac
