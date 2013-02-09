#!/bin/sh

usage() {
    echo "`basename $0` [-color] [-intir|-mars|-spim|-qemu|-x86] [ctigre]"
}

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

if [ "$asm_flags" != "" ]; then
    asm_msg="(flags:$asm_flags) "
fi

case $interp in
    -intir) msg="interpretor";;
    -spim) msg="compilation to Mips asm $asm_msg&& execution via Spim";;
    -mars) msg="compilation to Mips asm $asm_msg&& execution via Mars";;
    -qemu) msg="cross-compilation to Mips ELF $asm_msg&& execution via qemu-mips";;
    -x86) msg="compilation to x86 ELF $asm_msg&& native execution";;
esac

echo "[ CTigre test shell script : $msg ]"

[ "$1" = "" ] && ctigre=./ctigre || ctigre=$1

total=0
ok=0

cd `dirname $0`

for i in `find TESTS -name \*.tg`; do
    if [ -f $i.out ]; then
	echo -n .
	total=`expr $total + 1`
	[ -f $i.in ] && input=$i.in || input=/dev/null
	sh run.sh $asm_flags $interp $ctigre $i < $input > $i.log 2>&1
	cmp -s $i.out $i.log && ok=`expr $ok + 1` || echo "$i FAILED (check $i.log)"
    fi
done

percent=`expr $ok \* 100 / $total`

echo
echo "SCORE: $ok / $total ( $percent %)"
echo 

[ $ok = $total ] && exit 0 || exit 1
