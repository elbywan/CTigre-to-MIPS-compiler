	.data
L003__str:	.asciiz " <== address\n"
	.data
L002__str:	.asciiz " <== value at [0] (is an address)\n"
	.data
L001__str:	.asciiz " <== value at [0][0] (is -1)\n"
	.data
L000__str:	.asciiz " <== value at [0][0] (is -3)"

	.text
# main:
sub $sp, $sp, 156
move $fp, $sp

L011__block_entry:
li $t0, 0
sw $t0, 0($fp)
lw $t0, 0($fp)
sw $t0, 4($fp)
li $t0, 2
sw $t0, 8($fp)
lw $t0, 8($fp)
sw $t0, 12($fp)
li $t0, 1
sw $t0, 16($fp)
lw $t1, 12($fp)
mul $t0, $t1, 4
sw $t0, 20($fp)
lw $t1, 20($fp)
lw $t2, 16($fp)
mul $t0, $t1, $t2
sw $t0, 24($fp)
sub $sp, $sp, 4
lw $t0, 24($fp)
sw $t0, 0($sp)
jal malloc
sw $v0, 28($fp)
add $sp, $sp, 4

L004__array_check:
li $t0, 1
sw $t0, 32($fp)
lw $t1, 12($fp)
lw $t2, 32($fp)
sub $t0, $t1, $t2
sw $t0, 36($fp)
lw $t0, 36($fp)
sw $t0, 12($fp)
li $t0, 0
sw $t0, 40($fp)
lw $t1, 12($fp)
lw $t2, 40($fp)
bge $t1, $t2, L005__array_do

L006__array_done:
lw $t0, 28($fp)
sw $t0, 44($fp)
sub $sp, $sp, 4
lw $t0, 44($fp)
sw $t0, 0($sp)
jal printint
add $sp, $sp, 4
la $t0, L003__str
sw $t0, 48($fp)
sub $sp, $sp, 4
lw $t0, 48($fp)
sw $t0, 0($sp)
jal print
add $sp, $sp, 4
lw $t1, 44($fp)
lw $t0, 4($t1)
sw $t0, 52($fp)
sub $sp, $sp, 4
lw $t0, 52($fp)
sw $t0, 0($sp)
jal printint
add $sp, $sp, 4
la $t0, L002__str
sw $t0, 56($fp)
sub $sp, $sp, 4
lw $t0, 56($fp)
sw $t0, 0($sp)
jal print
add $sp, $sp, 4
lw $t1, 44($fp)
lw $t0, 0($t1)
sw $t0, 60($fp)
lw $t1, 60($fp)
lw $t0, 0($t1)
sw $t0, 64($fp)
sub $sp, $sp, 4
lw $t0, 64($fp)
sw $t0, 0($sp)
jal printint
add $sp, $sp, 4
la $t0, L001__str
sw $t0, 68($fp)
sub $sp, $sp, 4
lw $t0, 68($fp)
sw $t0, 0($sp)
jal print
add $sp, $sp, 4
lw $t1, 44($fp)
lw $t0, 4($t1)
sw $t0, 72($fp)
lw $t1, 72($fp)
lw $t0, 0($t1)
sw $t0, 76($fp)
sub $sp, $sp, 4
lw $t0, 76($fp)
sw $t0, 0($sp)
jal printint
add $sp, $sp, 4
la $t0, L000__str
sw $t0, 80($fp)
sub $sp, $sp, 4
lw $t0, 80($fp)
sw $t0, 0($sp)
jal print
sw $v0, 84($fp)
add $sp, $sp, 4
j L010__done

L005__array_do:
lw $t1, 12($fp)
mul $t0, $t1, 4
sw $t0, 88($fp)
lw $t1, 28($fp)
lw $t2, 88($fp)
add $t0, $t1, $t2
sw $t0, 92($fp)
lw $t0, 92($fp)
sw $t0, 96($fp)
li $t0, 2
sw $t0, 100($fp)
lw $t0, 100($fp)
sw $t0, 104($fp)
li $t0, 1
sw $t0, 108($fp)
lw $t1, 104($fp)
mul $t0, $t1, 4
sw $t0, 112($fp)
lw $t1, 112($fp)
lw $t2, 108($fp)
mul $t0, $t1, $t2
sw $t0, 116($fp)
sub $sp, $sp, 4
lw $t0, 116($fp)
sw $t0, 0($sp)
jal malloc
sw $v0, 120($fp)
add $sp, $sp, 4

L007__array_check:
li $t0, 1
sw $t0, 124($fp)
lw $t1, 104($fp)
lw $t2, 124($fp)
sub $t0, $t1, $t2
sw $t0, 128($fp)
lw $t0, 128($fp)
sw $t0, 104($fp)
li $t0, 0
sw $t0, 132($fp)
lw $t1, 104($fp)
lw $t2, 132($fp)
bge $t1, $t2, L008__array_do

L009__array_done:
lw $t1, 120($fp)
lw $t0, 96($fp)
sw $t1, 0($t0)
j L004__array_check

L008__array_do:
lw $t1, 104($fp)
mul $t0, $t1, 4
sw $t0, 136($fp)
lw $t1, 120($fp)
lw $t2, 136($fp)
add $t0, $t1, $t2
sw $t0, 140($fp)
lw $t0, 140($fp)
sw $t0, 144($fp)
li $t0, 1
sw $t0, 148($fp)
lw $t1, 4($fp)
lw $t2, 148($fp)
sub $t0, $t1, $t2
sw $t0, 152($fp)
lw $t0, 152($fp)
sw $t0, 4($fp)
lw $t1, 4($fp)
lw $t0, 144($fp)
sw $t1, 0($t0)
j L007__array_check

L010__done:
add $fp, $fp, 156
add $sp, $sp, 156
jal exit


# Assembler runtime support for CTigre
# CTigre wrappers for the SPIM bare OS functions, as
# necessary to implement the predefined library functions in CTigre
# (C) Roberto Di Cosmo 2003
# (C) Gr�goire Henry 2009

# The structure of the stack after a CTigre call is:
#
#
#             parameter n
#	      ...
#     SP ->   parameter 1

.text

### OUTPUT

printint:
	addi $sp $sp -8
	sw $fp ($sp)
	sw $ra 4($sp)
	addi $fp $sp 8

	lw $a0 0($fp)	# find parameter passed on the stack (integer)
	li $v0 1	# load system call code for print_int
	# here we (may) save the return address in the place where the parameter was passed
	syscall         # call the OS

	lw $ra 4($sp)
	lw $fp 0($sp)
	addi $sp $sp 8
	jr $ra		# return to CTigre calling function

print:
	addi $sp $sp -8
	sw $fp ($sp)
	sw $ra 4($sp)
	addi $fp $sp 8

	lw $a0 ($fp)	# find parameter passed on the stack (zero terminated string)
	li $v0 4	# load system call code for print_string
	syscall		# call the OS

	lw $ra 4($sp)
	lw $fp 0($sp)
	addi $sp $sp 8
	jr $ra		# return to CTigre calling function


### INPUT

readint:
	addi $sp $sp -8
	sw $fp ($sp)
	sw $ra 4($sp)
	addi $fp $sp 8

	li $v0 5	# load system call code for read_int
	syscall         # call the OS
	                # result is already in $v0
	lw $ra 4($sp)
	lw $fp 0($sp)
	addi $sp $sp 8
	jr $ra		# return to CTigre calling function


getstring:
	addi $sp $sp -12
	sw $fp 4($sp)
	sw $ra 8($sp)
	addi $fp $sp 12

	# allocate a chunk of memory to hold the string buffer
	lw  $a1 0($fp)	# length we have been passed
	add $a1 $a1 1   # add one for 0 termination
	sw $a1 0($sp)
	jal malloc      # call malloc

	add $a0 $0 $v0	# store the address of the allocated string buffer in $a0
	lw  $a1 0($fp)	# we read a string of length up to the parameter we have been passed
	add $a1 $a1 1   # add one for 0 termination
	li  $v0 8
	sw  $a0 0($sp)   # save string pointer
	syscall		# call the OS
	lw $v0 0($sp)    # result register contains string pointer

	lw $ra 8($sp)
	lw $fp 4($sp)
	addi $sp $sp 12
	jr $ra		# return to CTigre calling function


getchar:
	addi $sp $sp -12
	sw $fp 4($sp)
	sw $ra 8($sp)
	addi $fp $sp 12

	add $a0 $0 $sp	# store the one-char string in first free cell on the stack
	li $a1 2	# we read a string of length 1, plus one byte for zero termination
	li $v0 8
	syscall		# call the OS
	lbu $2 0($sp)   # get the byte (unsigned) on the stack and put it into the result register as a 4 word quantity

	lw $ra 8($sp)
	lw $fp 4($sp)
	addi $sp $sp 12
	jr $ra		# return to CTigre calling function


### ALLOCATION

malloc:
	addi $sp $sp -8
	sw $fp ($sp)
	sw $ra 4($sp)
	addi $fp $sp 8

	lw $a0 0($fp)	# find parameter passed on the stack (amount of memory)

	add $a0 $a0 4   # add 4 to make sure we are not zeroed out by the stupid SPIM sbkr bug
	                # (SPIM zeores out on 4 byte boundaries!!!!)

	li $v0 9	# load system call code for sbrk
	syscall		# call the OS, on return address of block is in $v0
			# the result register already contains the result

	lw $ra 4($sp)
	lw $fp ($sp)
	addi $sp $sp 8
	jr $ra		# return to CTigre calling function

### CHAR / STRING OPERATIONS

	# ord and char are the id function, due to the (expensive) coding of chars as integers
chr:
ord:

	lw $2 0($sp)	# find parameter passed on the stack (integer), and just return it
	jr $ra		# return to CTigre calling function

	# size of a string
size:
	lw $a0 0($sp)	# find parameter passed on the stack (zero terminated string)
	li $v0 0	# $v0 will contain the length
__loop:	lbu $3 0($a0)   # load the next byte in the string in $3
	beqz $3 __end   # end if zero
	add $a0 $a0 1	#
	add $v0 $v0 1	#
	j __loop
__end:	jr $ra		# return to CTigre calling function

	# make a string from a char
mkstring:
	addi $sp $sp -12
	sw $fp 4($sp)
	sw $ra 8($sp)
	addi $fp $sp 12

        li $v0 2
	sw $v0 0($sp)
	jal malloc
	lw $t0 0($fp)
	sb $t0 0($v0)
	sb $0  1($v0)

	lw $ra 8($sp)
	lw $fp 4($sp)
	addi $sp $sp 12
	jr $ra		# return to CTigre calling function

concat:
	addi $sp $sp -28
	sw $fp 4($sp)
	sw $ra 8($sp)
	addi $fp $sp 28

	lw $t0  4($fp)	# find second parameter passed on the stack (pointer to second string)
	sw $t0  0($sp)
	jal size
	sw  $v0 -4($fp) # in -4($fp), size of second string
	lw $t0  0($fp)	# find first parameter passed on the stack (pointer to first string)
        sw $t0  0($sp)
	jal size
	sw $v0  -8($fp) # in -8($fp), size of first string
	lw $t0 -4($fp) # compute size of new string
	add $t0 $v0 $t0
	sw $t0 -12($fp) # -12($fp) contains new size without zero
	add $t0 $t0 1   # plus one for the terminating zero
	sw $t0 0($sp)   # call malloc
	jal malloc
	                # now do the copy
	add $t0 $v0 0   # in $v0, base address of new string
	lw $a0 0($fp)   # address of first string
	lw $a1 -8($fp) # size of first string
__loop01:
	beqz $a1, __end01
	lbu  $3, 0($a0) # load char
	sb   $3, 0($t0) # store char
	add  $t0 $t0 1
	add  $a0 $a0 1
	sub  $a1 $a1 1
	j __loop01
__end01:
	lw $a0 4($fp)   # address of second string
	lw $a1 -4($fp) # size of second string
__loop02:
	beqz $a1, __end02
	lbu  $3, 0($a0) # load char
	sb   $3, 0($t0) # store char
	add  $t0 $t0 1
	add  $a0 $a0 1
	sub  $a1 $a1 1
	j __loop02
__end02:
	sb $0 0($t0)    # terminate new string

	lw $ra 8($sp)
	lw $fp 4($sp)
	addi $sp $sp 28
	jr $ra		# return to CTigre calling function

### EXIT

exit:
	li $v0 10
	syscall
