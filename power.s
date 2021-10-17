.text #read-only segment to store strings
info: .asciz "Result: %ld \n"	
twonr: .asciz "%ld %ld"

.global main #start running the program at main subroutine
main:
	# prologue
	pushq %rbp				#push the base pointer
	movq %rsp, %rbp			#copy stack pointer value to base pointer

	#read 2 numbers using scanf
	subq $16, %rsp 			#reserve space in stack for input
	leaq -16(%rbp), %rsi 	#first parameter at address of reserved space
	leaq -8(%rbp), %rdx		#second parameter at address of reserved space
	movq $twonr, %rdi 		#input format string
	movq $0, %rax			#no vector registers for scanf
	call scanf				#call scanf for user input
	popq %rsi 				#pop the value from stack to RSI (base)
	movq %rsi, %rdi 		#copy the value of RSI(base) to RDI (first argument calling convention)
	popq %rdx				#pop the value from stack to RDX (exponent)
	movq %rdx, %rsi 		#copy the value of RDX(exponent) to RSI (second argument calling convention)
	addq $16, %rsp 			#clean the stack
	# now, we have RDI - base, RSI - exponent

	cmpq $0, %rdi 			#compare if RDI is 0 (for 0^0 case)
	je zerotest				#jump to zerotest subroutine to test if RSI is 0 too

zerocontinue: #come back if RSI is not 0

	call pow 				#call the pow subroutine

	#print the result
	movq %rax, %rsi 		#move the result (RAX) to RSI
	movq $0, %rax			#no vector registers for printf
	movq $info, %rdi 		#output format string
	call printf				#print the result

end:
	#epilogue
	movq %rbp, %rsp 		#clear the local variables from stack 
	popq %rbp				#restore base pointer location
	#exit the program
	movq $0, %rdi 			
	call exit

pow:
	#prologue
	pushq %rbp 				#push the base pointer
	movq %rsp, %rbp 		#copy stack pointer value to base pointer

	movq $1, %rax			#copy the value 1 to RAX (for remembering the result)
	jmp loop 				#jump the loop subroutine

break:

	#epilogue
	movq %rbp, %rsp 		#clear the local variables from stack 
	popq %rbp				#restore base pointer location
	ret 					#return from subroutine pow

loop:
	cmpq $0, %rsi 			#compare $0 to RSI (remaining exponent)
	je break 				#if it's 0, jump to break to return from loop, otherwise continue
	
	mul %rdi 				#multiply the value stored in RAX(result) with RDI(base) and store it in RAX  
	decq %rsi 				#decrease the value stored in RSI(exponent) by 1

	jmp loop 				#jump to the beginning of the loop

zerotest:
	cmpq $0, %rsi 			#compare if RSI is 0 (0^0 case)
	je zerocase 			#jump to 0^0 case as both RDI and RSI are 0
	jmp zerocontinue 		#jump back to main and continue the program, as RSI is not 0

zerocase:
	movq $0, %rax			#no vector registers for printf
	movq $info, %rdi 		#output format string
	movq $1, %rsi
	call printf				#print the 0^0 case string

	jmp end 				#exit the program
