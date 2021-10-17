.text
char: .asciz "%c"
val: .asciz "%ld"

color: .asciz "\033[38;5;%d;48;5;%dm"

reset: .asciz "\033[0m"
blink: .asciz "\033[5m"
stop_blink: .asciz "\033[25m"
bold: .asciz "\033[1m"
faint: .asciz "\033[2m"
conceal: .asciz "\033[8m"
reveal: .asciz "\033[28m"

.include "final.s"

.global main


decode:
	# prologue
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	pushq %rbx
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15

# r12 - address of MESSAGE
# r13 - current block of message
# r14 - number of times the character should be printed
# r15 - next block of character
# rbx - character that should be printed
	movq %rdi, %r12
	movq $0, %r15

loop:
	movq (%r12, %r15, 8), %r13

	movq $0, %rbx
	movb %r13b, %bl 			#character in %rbx
	
	shr $8, %r13
	movq $0, %r14				#number of times the character should be printed in %rdx
	movb %r13b, %r14b 			

	shr $8, %r13
	movq $0, %r15				#next memory block in %r15
	movl %r13d, %r15d

	shr $32, %r13
	movq $0, %rsi 				#foreground color
	movb %r13b, %sil

	shr $8, %r13 
	movq $0, %rdx				#background color
	movb %r13b, %dl

	cmpq %rdx, %rsi
	je effect
	jmp continue

	effect:
		cmpq $0, %rsi
		je reset_effect
		cmpq $182, %rsi
		je blink_effect
		cmpq $37, %rsi
		je noblink_effect
		cmpq $42, %rsi
		je bold_effect
		cmpq $66, %rsi
		je faint_effect
		cmpq $105, %rsi
		je conceal_effect
		cmpq $153, %rsi
		je reveal_effect

		reset_effect:
			movq $reset, %rdi
			jmp apply_effect
		blink_effect:
			movq $blink, %rdi
			jmp apply_effect
		noblink_effect:
			movq $stop_blink, %rdi
			jmp apply_effect
		bold_effect:
			movq $bold, %rdi
			jmp apply_effect
		faint_effect:
			movq $faint, %rdi
			jmp apply_effect
		conceal_effect:
			movq $conceal, %rdi
			jmp apply_effect
		reveal_effect:
			movq $reveal, %rdi
			jmp apply_effect

			apply_effect:
				movq $0, %rax
				call printf
				jmp printing
	
continue:
	movq $color, %rdi 
	movq $0, %rax 
	call printf

printing:
	movq %rbx, %rsi
	movq $0, %rax
	movq $char, %rdi 
	call printf

	decq %r14
	cmpq $0, %r14 
	jne printing

	cmpq $0, %r15
	jne loop

	movq $0, %rax
	movq $reset, %rdi
	call printf 

	popq %r15
	popq %r14
	popq %r13
	popq %r12
	popq %rbx

	# epilogue
	movq %rbp, %rsp		# clear local variables from stack
	popq %rbp			# restore base pointer location
	ret



main:
	pushq %rbp 			# push the base pointer (and align the stack)
	movq %rsp, %rbp		# copy stack pointer value to base pointer

	movq $MESSAGE, %rdi	# first parameter: address of the message
	call decode			# call decode

	popq %rbp			# restore base pointer location 
	movq $0, %rdi		# load program exit code
	call exit			# exit the program
