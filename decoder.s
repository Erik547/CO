.text
char: .asciz "%c"

.include "andy.s"

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

# r12 - address of MESSAGE
# r13 - current block of message
# r14 - number of times the character should be printed
# r15 - next block of character
# rbx - character that should be printed

loop:
	#we now move the first 8 bytes from %r12 with displacement %r15*8
	#when %r15 is 0, the first memory block is (.quad in final.s) in %r13
	#when %r15 is 1, the second memory block is in %r13 and so on...
	movq (%r12, %r15, 8), %r13  

	movq $0, %rbx		#clear %rbx
	movb %r13b, %bl 	#move the character (first byte) in %rbx
	
	shr $8, %r13 		#right-shift %r13 by 8 bits to get the second byte
	movq $0, %r14 		#clear %r14
	movb %r13b, %r14b 	#move the number of times the character should be printed in %r14

	shr $8, %r13 		#right-shift %r13 by 8 bits to get the remaining bytes for next address
	movq $0, %r15		#clear %r15 
	movl %r13d, %r15d   #move 4 bytes to %r15 -> next memory block that we should jump to

printing:
	movq %rbx, %rsi     #move the character (ascii) from %rbx to %rsi
	movq $0, %rax       #no vector registers for printf
	movq $char, %rdi    #output format in %rdi
	call printf			#print the character

	decq %r14  			#decrease %r14 by 1 (number of times the character should be printed)
	cmpq $0, %r14       #check if the character should be printed again (is %r14 zero?)
	jne printing 		#if it's not zero, print the character again

	cmpq $0, %r15 		#check if the next memory block that we should jump to is 0
	jne loop  			#if it's not zero, jump to loop and take the next memory block 
						## if it's zero, we reached the end of the message.
	# epilogue
	movq %rbp, %rsp		# clear local variables from stack
	popq %rbp			# restore base pointer location
	ret

main:
	pushq %rbp 			# push the base pointer (and align the stack)
	movq %rsp, %rbp		# copy stack pointer value to base pointer

	movq $0, %r15 		# 0 in %r15 for the first memory block
	movq $MESSAGE, %r12	# first parameter: address of the message
	call decode			# call decode

	popq %rbp			# restore base pointer location 
	movq $0, %rdi		# load program exit code
	call exit			# exit the program
