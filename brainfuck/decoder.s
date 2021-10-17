.text
print: .asciz "%c"


.include "final.s"

.global main

# ************************************************************
# Subroutine: decode                                         *
# Description: decodes message as defined in Assignment 3    *
#   - 2 byte unknown                                         *
#   - 4 byte index                                           *
#   - 1 byte amount                                          *
#   - 1 byte character                                       *
# Parameters:                                                *
#   first: the address of the message to read                *
#   return: no return value                                  *
# ************************************************************
decode:
	# prologue
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	movq (%rdi), %r8		# move the value located at %rdi to %r8 ($MESSAGE in r8)

	movq $0, %rsi			# clear any values stored in %rsi
	movb %r8b, %sil			# move 1 byte from %r8b to %sil, second argument for loop, the character to be printed
	shr $8, %r8				# shifting the value in %r8 to the right with 8 bits

	movq $0, %rdi			# clear any values stored in %rdi
	movb %r8b, %dil			# move 1 byte from %r8b to %dil, first argument for loop, the number of prints
    shr $8, %r8				# shift the value in %r8 to the right with 8 bits

	movq $0, %r10			# clear any values stored in %r10
	movl %r8d, %r10d		# move 4 bytes from %r8d to %r10d (address of the next memory block to jump to)
	pushq %r10				# push the value in r10 to store it

	cmpl $0, %r8d			# compares if the next memory address is at line 0 in the message
	je brek					# if equal it jumps to brek
	
	call loop				# calls loop to print the character

	movq $0, %r8			# clear any values stored in %r8 (we will use r8 for the value of the next memory block)
	popq %r8				# pop the remaining value from the stack in %r8
	movl %r8d, %eax			# moving 4 bytes from %r8 to %rax
	movq $8, %r8			# move the value 8 in %r8
	mulq %r8				# multiply the value in %rax with the value in %r8(8) to obtain the offset added to $MESSAGE
	addq $MESSAGE, %rax		# add the memory address of MESSAGE to the value in %rax to obtain the next memory address
	movq %rax, %rdi			# moving the next memory address to %rdi, parameter for the decode subroutine
	
	call decode				# call decode again
	
	# epilogue
	movq	%rbp, %rsp		# clear local variables from stack
	popq	%rbp			# restore base pointer location 
	ret						# pops the return value off the stack and jumps to it

main:
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	movq	$MESSAGE, %rdi	# first parameter: first block of message
	call	decode			# call decode

	popq	%rbp			# restore base pointer location 
	movq	$0, %rdi		# load program exit code
	call	exit			# exit the program

loop:						# prints the character received in rsi the number of times received in rdi
    # prologue
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

    cmpq $0, %rdi			# compares if there are any more prints left to do
    jle brek				# if less or equal jumps to brek

	pushq %rsi				# pushes the value in %rsi to store it, printf changes values in registers
	pushq %rdi				# pushes the value in %rdi to store it, printf changes values in registers
    movq $print, %rdi		# moves the print format to %rdi
    movq $0, %rax			# no vector registers for printf
    call printf 			# calls printf

	movq $0, %rdi			# clears any values in %rdi
	popq %rdi				# pops the number of prints off the stack in %rdi
	movq $0, %rsi			# clears any values in %rsi
	popq %rsi				# pops the character off the stack in %rsi, second argument for loop

	subq $1, %rdi			# subtracts 1 from the number of prints left
    call loop				# calls loop

    movq	%rbp, %rsp		# clear local variables from stack
	popq	%rbp			# restore base pointer location 
	ret
brek:						# executes epilogue and return in recursive subroutines decode and loop
    movq	%rbp, %rsp		# clear local variables from stack
	popq	%rbp			# restore base pointer location 
	ret						# pops the return value off the stack and jumps to it


