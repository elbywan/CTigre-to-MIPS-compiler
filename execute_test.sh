#!/bin/sh

if [ ! -x ./ctigre ]; then 
	echo "Program ctigre not found, or not executable."
	exit
fi

if [ $# -gt 1 -a "$1" = "-save" ]; then
	file=$2
	args=""
	while [ $# -gt 2 ]; do
		args="$args $3"
		shift
	done
	if [ ! -r $file ]; then
		echo "File not found or not readable."
		exit
	fi 
	if [ ! -d ./Out ]; then  
		mkdir ./Out 
	fi
	./ctigre -asm $file $args > ./Out/temp.s
	cat runtime.s >> ./Out/temp.s
	exit
fi 

if [ $# -gt 1 -a "$1" = "-kate" ]; then
	file=$2
	args=""
	while [ $# -gt 2 ]; do
		args="$args $3"
		shift
	done
	if [ ! -r $file ]; then
		echo "File not found or not readable."
		exit
	fi 
	if [ ! -d ./Out ]; then  
		mkdir ./Out
	fi
	./ctigre -asm $file $args > ./Out/temp.s
	kate ./Out/temp.s
	exit
fi 

if [ $# -gt 1 -a "$1" = "-mars" ]; then
	file=$2
	args=""
	while [ $# -gt 2 ]; do
		args="$args $3"
		shift
	done
	if [ ! -r $file ]; then
		echo "File not found or not readable."
		exit
	fi 
	if [ ! -d ./Out ]; then  
		mkdir ./Out 
	fi
	./ctigre -asm $file $args > ./Out/temp.s
	cat runtime.s >> ./Out/temp.s
	mars ./Out/temp.s 
	rm -r ./Out
	exit
fi

if [ $# -gt 0 ]; then
	file=$1
	args=""
	while [ $# -gt 1 ]; do
		args="$args $2"
		shift
	done
	if [ ! -r $file ]; then
		echo "File not found or not readable."
		exit
	fi 
	if [ ! -d ./Out ]; then  
		mkdir ./Out 
	fi
	./ctigre -asm $file $args > ./Out/temp.s
	cat runtime.s >> ./Out/temp.s
	spim -file ./Out/temp.s | tail -n +6
	echo ""
	rm -r ./Out
	exit
fi

echo "Nécessite au moins un argument : execute_test.sh [-save | -kate | -mars] fichier [arguments optionnels de ctigre]."