.text
print: .asciz "%c"

.data
foreground: .asciz "\033[38;5;%dm%c"
background: .asciz "\033[48;5;%dm"
resetformat: .asciz "\033[m"
stopblink: .asciz "\033[25m%c"
bold: .asciz "\033[1m%c"
faint: .asciz "\033[2m%c"
conceal: .asciz "\033[8m%c"
reveal: .asciz "\033[28m%c"
blink: .asciz "\033[5m%c"


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



# trebuie reset ca sa resetez culoarea terminalului
# printez mai intai background si dupa foreground


decode:
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	movq %rdi, %rsi			# moves second argument in rsi for decode2
	call decode2			# calls decode2

	movq	%rbp, %rsp		# clear local variables from stack
	popq	%rbp			# restore base pointer location 
	ret

main:
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	movq	$MESSAGE, %rdi	# first parameter: first block of message
	call	decode			# call decode

	#call reset

	popq	%rbp			# restore base pointer location 
	movq	$0, %rdi		# load program exit code
	call	exit			# exit the program

loop:						# prints the character received in rsi the number of times received in rdi
    # prologue
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	
    cmpq $0, %rdi			# compares if there are any more prints left to do
    jle brek				# if less or equal jumps to brek

	pushq %rsi				# push %rsi (character that we print)
	pushq %rdi				# push %rdi (number of times we print)
	pushq %rdx				# push %rdx  (foreground color)
	pushq %rcx				# push %rcx   (background color)

	cmpq %rcx, %rdx			# compares if the colors are the same or not
	jne printing			# if not it jumps to printing label to print them normally

	cmpq $0, %rdx			
	je reset1 				# if the value in rdx is equal to 0 it jumps to reset

	cmpq $37, %rdx
	je stopblinking			# if the value in rdx is 37 it jumps to stop blinking to only print with the specified colors

	cmpq $42, %rdx			
	je bold1				# if the value in rdx is 42 then it jumps to bold to print the text in bold

	cmpq $66, %rdx
	je faint1				# if the value in rdx is 66 it jumps to faint to print the text faint

	cmpq $105, %rdx
	je conceal1				# if the value in rdx is 105 it jumps to conceal to conceal the text

	cmpq $153, %rdx
	je reveal1				# if the value in rdx is 153 it jumps to reveal to reveal the text

	cmpq $182, %rdx
	je blink1				# if the value in rdx is 182 it jumps to blink so the printed text will blink

printing:
	movq $background, %rdi	# moves the print format to rdi, first argument
	movq %rcx, %rsi			# moves the background color to rsi, second argument
	movq $0, %rax			# no vector registers for printf
	call printf				# calls printf

	addq $8, %rsp
	popq %rsi				# pops the text color value off the stack in rsi

	addq $8, %rsp 			# alligns the stack
	popq %rdx				# pops the character value off the stack in rdx third argument for printf
	subq $32, %rsp			# alligns the stack

    movq $foreground, %rdi	# moves the print format to %rdi
    movq $0, %rax			# no vector registers for printf
    call printf 			# calls printf

	popq %rcx				# pops the text color value
	popq %rdx				# pops the background color value
	movq $0, %rdi			# clears any values in %rdi
	popq %rdi				# pops the number of prints off the stack in %rdi
	movq $0, %rsi			# clears any values in %rsi
	popq %rsi				# pops the character off the stack in %rsi, second argument for loop

	subq $1, %rdi			# subtracts 1 from the number of prints left
    call loop				# calls loop

    movq	%rbp, %rsp		# clear local variables from stack
	popq	%rbp			# restore base pointer location 
	ret						# pops the return address off the stack and jumps to it

brek2: # used to reset color before exiting the program
	call reset				# calls reset so the terminal will reset
	movq	%rbp, %rsp		# clear local variables from stack
	popq	%rbp			# restore base pointer location 
	ret						# pops the return address off the stack and jumps to it

brek: # executes epilogue and return in recursive subroutines decode and loop
    movq	%rbp, %rsp		# clear local variables from stack
	popq	%rbp			# restore base pointer location 
	ret						# pops the return value off the stack and jumps to it

reset1:
	call reset				# calls reset
	jmp printing			# jumps to printing

stopblinking:
	addq $24, %rsp
	popq %rsi				# pops the character to be printed from the stack
	subq $32, %rsp			# alligns the stack back

    movq $stopblink, %rdi	# moves the print format to %rdi
    movq $0, %rax			# no vector registers for printf
    call printf 			# calls printf

	popq %rcx				# pops the text color value
	popq %rdx				# pops the background color value
	movq $0, %rdi			# clears any values in %rdi
	popq %rdi				# pops the number of prints off the stack in %rdi
	movq $0, %rsi			# clears any values in %rsi
	popq %rsi				# pops the character off the stack in %rsi, second argument for loop

	subq $1, %rdi			# subtracts 1 from the number of prints left
    call loop				# calls loop

    movq	%rbp, %rsp		# clear local variables from stack
	popq	%rbp			# restore base pointer location 
	ret						# pops the return address off the stack and jumps to it
bold1:
	addq $24, %rsp
	popq %rsi				# pops the character to be printed from the stack
	subq $32, %rsp			# alligns the stack back

    movq $bold, %rdi		# moves the print format to %rdi
    movq $0, %rax			# no vector registers for printf
    call printf 			# calls printf

	popq %rcx				# pops the text color value
	popq %rdx				# pops the background color value
	movq $0, %rdi			# clears any values in %rdi
	popq %rdi				# pops the number of prints off the stack in %rdi
	movq $0, %rsi			# clears any values in %rsi
	popq %rsi				# pops the character off the stack in %rsi, second argument for loop

	subq $1, %rdi			# subtracts 1 from the number of prints left
    call loop				# calls loop

    movq	%rbp, %rsp		# clear local variables from stack
	popq	%rbp			# restore base pointer location 
	ret
faint1:
	addq $24, %rsp
	popq %rsi				# pops the character to be printed from the stack
	subq $32, %rsp			# alligns the stack back

    movq $faint, %rdi		# moves the print format to %rdi
    movq $0, %rax			# no vector registers for printf
    call printf 			# calls printf

	popq %rcx				# pops the text color value
	popq %rdx				# pops the background color value
	movq $0, %rdi			# clears any values in %rdi
	popq %rdi				# pops the number of prints off the stack in %rdi
	movq $0, %rsi			# clears any values in %rsi
	popq %rsi				# pops the character off the stack in %rsi, second argument for loop

	subq $1, %rdi			# subtracts 1 from the number of prints left
    call loop				# calls loop

    movq	%rbp, %rsp		# clear local variables from stack
	popq	%rbp			# restore base pointer location 
	ret						# pops the return value from the stack and continues from there
conceal1:
	addq $24, %rsp
	popq %rsi				# pops the character to be printed from the stack
	subq $32, %rsp			# alligns the stack back

    movq $conceal, %rdi		# moves the print format to %rdi
    movq $0, %rax			# no vector registers for printf
    call printf 			# calls printf

	popq %rcx				# pops the text color value
	popq %rdx				# pops the background color value
	movq $0, %rdi			# clears any values in %rdi
	popq %rdi				# pops the number of prints off the stack in %rdi
	movq $0, %rsi			# clears any values in %rsi
	popq %rsi				# pops the character off the stack in %rsi, second argument for loop

	subq $1, %rdi			# subtracts 1 from the number of prints left
    call loop				# calls loop

    movq	%rbp, %rsp		# clear local variables from stack
	popq	%rbp			# restore base pointer location 
	ret						# pops the return arddress off the stack and jumps to it
reveal1:
	addq $24, %rsp
	popq %rsi				# pops the character to be printed from the stack
	subq $32, %rsp			# alligns the stack back

    movq $reveal, %rdi		# moves the print format to %rdi
    movq $0, %rax			# no vector registers for printf
    call printf 			# calls printf

	popq %rcx				# pops the text color value
	popq %rdx				# pops the background color value
	movq $0, %rdi			# clears any values in %rdi
	popq %rdi				# pops the number of prints off the stack in %rdi
	movq $0, %rsi			# clears any values in %rsi
	popq %rsi				# pops the character off the stack in %rsi, second argument for loop

	subq $1, %rdi			# subtracts 1 from the number of prints left
    call loop				# calls loop

    movq	%rbp, %rsp		# clear local variables from stack
	popq	%rbp			# restore base pointer location 
	ret						# pops the return arddress off the stack and jumps to it
blink1:
	addq $24, %rsp
	popq %rsi				# pops the character to be printed from the stack
	subq $32, %rsp			# alligns the stack back

    movq $blink, %rdi		# moves the print format to %rdi
    movq $0, %rax			# no vector registers for printf
    call printf 			# calls printf

	popq %rcx				# pops the text color value
	popq %rdx				# pops the background color value
	movq $0, %rdi			# clears any values in %rdi
	popq %rdi				# pops the number of prints off the stack in %rdi
	movq $0, %rsi			# clears any values in %rsi
	popq %rsi				# pops the character off the stack in %rsi, second argument for loop

	subq $1, %rdi			# subtracts 1 from the number of prints left
    call loop				# calls loop

    movq	%rbp, %rsp		# clear local variables from stack
	popq	%rbp			# restore base pointer location 
	ret						# pops the return arddress off the stack and jumps to it

decode2:
	# prologue
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	pushq %rsi				# stores the MESSAGE address in the stack
	

	movq (%rdi), %r8		# move the value located at %rdi to %r8 (the .quad from message)
	movq $0, %rsi			# clear any values stored in %rsi 
	movb %r8b, %sil			# move a byte from %r8b to %sil, second argument for loop, the character to be printed
	shr $8, %r8				# shifting the value in %r8 to the right with 8 bits

	movq $0, %rdi			# clear any values stored in %rdi
	movb %r8b, %dil			# move a byte from %r8b to %dil, first argument for loop, the number of prints
    shr $8, %r8				# shift the value in %r8 to the right with 8 bits

	movq $0, %r10			# clear any values stored in %r10
	movl %r8d, %r10d		# move 4 bytes from %r8d to %r10d (next memory block we will jump to)
	pushq %r10				# push the value in r10 to store it

	cmpl $0, %r8d			# compares if the next memory address is 0
	je brek2				# if equal it jumps to brek2
	
	shr $32, %r8			# shifts 32 bits to the right
	movq $0, %rdx
	movb %r8b, %dl			# moves the text color to dl

	shr $8, %r8				# shifts 8 bits to the right
	movq $0, %rcx
	movb %r8b, %cl			# moves the background color to cl
	
	call loop				# calls loop to print the character

	movq $0, %r8			# clear any values stored in %r8
	popq %r8				# pop the next memory block we will jump to from the stack in %r8
	movq $0, %rax 			# clear %rax
	movl %r8d, %eax			# moving 4 bytes from %r8 to %rax
	movq $8, %r8			# move the value 8 in %r8
	mulq %r8				# multiply the value in %rax with the value in %r8(8) to obtain the offset added to $MESSAGE
	popq %rsi
	addq %rsi, %rax			# add the memory address of MESSAGE to the value in %rax to obtain the next memory address
	movq %rax, %rdi			# moving the next memory address to %rdi, parameter for the decode subroutine
	
	call decode2			# call decode again
	
	# epilogue
	movq	%rbp, %rsp		# clear local variables from stack
	popq	%rbp			# restore base pointer location 
	ret						# pops the return value off the stack and jumps to it

reset:
	# prologue
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	movq $resetformat, %rdi	# moves the reset format to rdi, first argument
	movq $0, %rsi
	movq $0, %rax			# no vector registers for printf
	call printf				# calls printf
	# epilogue
	movq	%rbp, %rsp		# clear local variables from stack
	popq	%rbp			# restore base pointer location 
	ret						# pops the return value off the stack and jumps to it

