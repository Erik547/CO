.text #read-only segment to store strings	
onenr: .asciz "%lu"
answer: .asciz "The answer is: %lu\n"

.global main #start running the program at main subroutine
main:
	# prologue
	pushq %rbp				#push the base pointer
	movq %rsp, %rbp			#copy stack pointer value to base pointer

	#read 1 number using scanf
	subq $16, %rsp 			#reserve space in stack for input
	leaq -16(%rbp), %rsi 	#first parameter at address of reserved space

	movq $onenr, %rdi 		#input format string
	movq $0, %rax			#no vector registers for scanf
	call scanf				#call scanf for user input
	popq %rsi 				#pop the value from stack to RSI
	movq %rsi, %rdi 		#copy the value of RSI(input) to RDI (first argument calling convention)

	addq $16, %rsp 			#clean the stack

	call factorial			#calls the factorial subroutine

	movq %rax, %rsi 		#move the result(RAX) in first argument (RSI)
	movq $0, %rax 			#no vector registers for printf
	movq $answer, %rdi 		#output format in %rdi 
	call printf   			#call printf

	movq %rbp, %rsp 		#clear the local variables from stack 
	popq %rbp				#restore base pointer location

end: 						#exit the program
	movq $0, %rdi 			#no exit code for exit functions(it doesn't report any errors)	
	call exit

factorial:
	# prologue
	pushq %rbp				#push the base pointer
	movq %rsp, %rbp			#copy stack pointer value to base pointer

	cmpq $1, %rdi 			#compare if RDI is 1 or less than 1, then initialize RAX
	jle initialize 			

	pushq %rdi  			#push %rdi to stack
	decq %rdi 				#decrease #rdi by 1
	call factorial 			#call the factorial subroutine again

multiply:
	popq %rdi 				#pop the current value from stack to %rdi 
	mulq %rdi 				#multiply %rax * %rdi and save to %rax

	cmpq $0, %rdi 			#if %rdi is not 0, then continue (jump over initialize)
	jne continue            

initialize:
	movq $1, %rax  			#initialize %rax to 1

continue:
	movq %rbp, %rsp 		#clear the local variables from stack 
	popq %rbp				#restore base pointer location
	ret

