	.data
L017__str:	.asciiz "\n"
	.data
L016__str:	.asciiz "\n"
	.data
L015__str:	.asciiz "\n"
	.data
L014__str:	.asciiz "\n"

	.text
# main:
sub $sp, $sp, 52
move $fp, $sp

L023__block_entry:
li $t0, 42
sw $t0, 0($fp)
sub $sp, $sp, 8
sw $fp, 0($sp)
lw $t0, 0($fp)
sw $t0, 4($sp)
jal L000__pair
sw $v0, 4($fp)
add $sp, $sp, 8
sub $sp, $sp, 4
lw $t0, 4($fp)
sw $t0, 0($sp)
jal printint
add $sp, $sp, 4
la $t0, L017__str
sw $t0, 8($fp)
sub $sp, $sp, 4
lw $t0, 8($fp)
sw $t0, 0($sp)
jal print
add $sp, $sp, 4
li $t0, 42
sw $t0, 12($fp)
sub $sp, $sp, 8
sw $fp, 0($sp)
lw $t0, 12($fp)
sw $t0, 4($sp)
jal L001__impair
sw $v0, 16($fp)
add $sp, $sp, 8
sub $sp, $sp, 4
lw $t0, 16($fp)
sw $t0, 0($sp)
jal printint
add $sp, $sp, 4
la $t0, L016__str
sw $t0, 20($fp)
sub $sp, $sp, 4
lw $t0, 20($fp)
sw $t0, 0($sp)
jal print
add $sp, $sp, 4
li $t0, 43
sw $t0, 24($fp)
sub $sp, $sp, 8
sw $fp, 0($sp)
lw $t0, 24($fp)
sw $t0, 4($sp)
jal L000__pair
sw $v0, 28($fp)
add $sp, $sp, 8
sub $sp, $sp, 4
lw $t0, 28($fp)
sw $t0, 0($sp)
jal printint
add $sp, $sp, 4
la $t0, L015__str
sw $t0, 32($fp)
sub $sp, $sp, 4
lw $t0, 32($fp)
sw $t0, 0($sp)
jal print
add $sp, $sp, 4
li $t0, 43
sw $t0, 36($fp)
sub $sp, $sp, 8
sw $fp, 0($sp)
lw $t0, 36($fp)
sw $t0, 4($sp)
jal L001__impair
sw $v0, 40($fp)
add $sp, $sp, 8
sub $sp, $sp, 4
lw $t0, 40($fp)
sw $t0, 0($sp)
jal printint
add $sp, $sp, 4
la $t0, L014__str
sw $t0, 44($fp)
sub $sp, $sp, 4
lw $t0, 44($fp)
sw $t0, 0($sp)
jal print
sw $v0, 48($fp)
add $sp, $sp, 4
add $fp, $fp, 52
add $sp, $sp, 52
jal exit



	.text
L001__impair:
sub $sp, $sp, 56
sw $fp, 52($sp)
sw $ra, 48($sp)
add $fp, $sp, 56

L021__block_entry:
li $t0, 0
sw $t0, 0($fp)
lw $t0, 4($fp)
sw $t0, 4($fp)
lw $t1, 4($fp)
lw $t2, 0($fp)
beq $t1, $t2, L011__op1

L012__op2:
li $t0, 0
sw $t0, 8($fp)
lw $t0, 8($fp)
sw $t0, 12($fp)

L013__op3:
li $t0, 1
sw $t0, 16($fp)
lw $t1, 12($fp)
lw $t2, 16($fp)
beq $t1, $t2, L008__if_ok

L009__of_notok:
li $t0, 1
sw $t0, 20($fp)
lw $t0, 4($fp)
sw $t0, 24($fp)
lw $t1, 24($fp)
lw $t2, 20($fp)
sub $t0, $t1, $t2
sw $t0, 28($fp)
lw $t0, 0($fp)
sw $t0, 32($fp)
sub $sp, $sp, 8
lw $t0, 32($fp)
sw $t0, 0($sp)
lw $t0, 28($fp)
sw $t0, 4($sp)
jal L000__pair
sw $v0, 36($fp)
add $sp, $sp, 8

L010__if_cont:
j L020__done

L011__op1:
li $t0, 1
sw $t0, 40($fp)
lw $t0, 40($fp)
sw $t0, 12($fp)
j L013__op3

L008__if_ok:
li $t0, 0
sw $t0, 44($fp)
lw $t0, 44($fp)
sw $t0, 36($fp)
j L010__if_cont

L020__done:
lw $v0, 36($fp)
lw $fp, 52($sp)
lw $ra, 48($sp)
add $sp, $sp, 56
jr $ra



	.text
L000__pair:
sub $sp, $sp, 56
sw $fp, 52($sp)
sw $ra, 48($sp)
add $fp, $sp, 56

L019__block_entry:
li $t0, 0
sw $t0, 0($fp)
lw $t0, 4($fp)
sw $t0, 4($fp)
lw $t1, 4($fp)
lw $t2, 0($fp)
beq $t1, $t2, L005__op1

L006__op2:
li $t0, 0
sw $t0, 8($fp)
lw $t0, 8($fp)
sw $t0, 12($fp)

L007__op3:
li $t0, 1
sw $t0, 16($fp)
lw $t1, 12($fp)
lw $t2, 16($fp)
beq $t1, $t2, L002__if_ok

L003__of_notok:
li $t0, 1
sw $t0, 20($fp)
lw $t0, 4($fp)
sw $t0, 24($fp)
lw $t1, 24($fp)
lw $t2, 20($fp)
sub $t0, $t1, $t2
sw $t0, 28($fp)
lw $t0, 0($fp)
sw $t0, 32($fp)
sub $sp, $sp, 8
lw $t0, 32($fp)
sw $t0, 0($sp)
lw $t0, 28($fp)
sw $t0, 4($sp)
jal L001__impair
sw $v0, 36($fp)
add $sp, $sp, 8

L004__if_cont:
j L018__done

L005__op1:
li $t0, 1
sw $t0, 40($fp)
lw $t0, 40($fp)
sw $t0, 12($fp)
j L007__op3

L002__if_ok:
li $t0, 1
sw $t0, 44($fp)
lw $t0, 44($fp)
sw $t0, 36($fp)
j L004__if_cont

L018__done:
lw $v0, 36($fp)
lw $fp, 52($sp)
lw $ra, 48($sp)
add $sp, $sp, 56
jr $ra


# Assembler runtime support for CTigre
# CTigre wrappers for the SPIM bare OS functions, as
# necessary to implement the predefined library functions in CTigre
# (C) Roberto Di Cosmo 2003
# (C) Grégoire Henry 2009

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
