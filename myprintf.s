.text #message format string
message: .asciz "%s %% %u %r hello bro woo %s %d %d %u %s %%hello lol\n"

#additional strings for %s format specifier
string: .asciz "Piet"
string2: .asciz "boss"

.global main

my_printf:
	# prologue
	pushq %rbp 			# push the base pointer (and align the stack)
	movq %rsp, %rbp		# copy stack pointer value to base pointer
	
	#push the values of the calle-saved registers to the stack
	pushq %r12  			#push %r12
	pushq %r13				#push %r13
	pushq %r14 				#push %r14
	pushq %r15 				#push %r15
	pushq %rbx 				#push %rbx

	movq %rdi, %r12     #message in %r12
	movq $0, %r13  		#start of message
	
test_if_more_arguments:
	cmpq $0, %rsi 		#verify if additional parameters exist on stack
	jg pushloop 		#if yes, push them
	jmp push_registers  #if not, push only the registers

	pushloop:
		movq %rbp, %r15   #move the value of the base pointer to %r15
		addq $16, %r15    #add 16 bytes to jump over %rbp, the return value and %rsi (pushed earlier in main)

	pushloop2:
		pushq (%r15)      #push the value found at %r15 to stack
		addq $8, %r15     #add 8 to get to the next value
		decq %rsi  		  #decrease %rsi by 1
		cmpq $0, %rsi     #check if there are any additional parameters left
		jg pushloop2      #if yes, jump to pushloop2 to push a parameter again

push_registers: 		  
	pushq %r9 			#push %r9 to the stack
	pushq %r8			#push %r8 to the stack
	pushq %rcx 			#push %rcx to the stack
	pushq %rdx  		#push %rdx to the stack 

# r12 - address for message format string
# r13 - current index in message (starts at 0 and increments by 1) (used to go over the string -
#       character by character with indirect memory addressing with displacement)
# r14 - current character that will be printed

loop:
	movq (%r12, %r13, 1), %r14  #move to %r14 the value from (%r12 + 1*%r13)

	cmpb $37, %r14b 			#compare if %r14b is % (used for format specifier, ASCII code 37)
	je specialchar  			#if it is, then we have to output a number/string/% and jump to specialchar

continue:
	addq %r13, %r12    			#add %r13 to %r12 to get the character

	#linux syscall for sys_write
	movq $1, %rax 				#1 in %rax for sys_write
	movq $1, %rdi  				#where to print (stdout)
	movq %r12, %rsi  			#character that should be printed in %rsi
	movq $1, %rdx 				#number of characters that should be printed (we always print only 1)
	syscall 					

	subq %r13, %r12 			#subtract %r13 from %r12 to restore the original address for message

	incq %r13 					#increase %r13 by 1 to get to the next character in message

	cmpb $0, %r14b 				#check if %r14 contains 0x00 (end of message)
	jne loop 					#if not, jump to loop again to print the next character

	#restore the values of the calle-saved registers from the stack
	popq %rbx 				#pop %rbx
	popq %r15 				#pop %r15
	popq %r14  				#pop %r14
	popq %r13				#pop %r13
	popq %r12 				#pop %r12

	# epilogue
	movq %rbp, %rsp		# clear local variables from stack
	popq %rbp			# restore base pointer location 
	ret

specialchar:
	incq %r13 						#increase %r13 to jump over the '%' sign 
	movq (%r12, %r13, 1), %r14 		#next character to test (u,d,s,%) for format specifier

	cmpb $117, %r14b 				#check if %r14b is 'u' (ASCII code 117)
	je digitchar 					#if it is, we need to output a number
	
	cmpb $100, %r14b 				#check if %r14b is 'd' (ASCII code 100)
	je signed_digit  				#if it is, we need to output a signed number (negative number)

	cmpb $37, %r14b 				#check if %r14b is '%' (ASCII code 37)
	je percentprint					#if it is, we need to output the percent sign '%'

	cmpb $115, %r14b 				#check if %r14b is 's' (ASCII code 115)
	je stringprint 					#if it is, we need to output a string

	decq %r13    	#case where no correct format specifier, decrease %r13 and continue printing
	jmp continue 	#jump to continue, this will output the character '%' with another character that isn't a correct format speicifer 

stringprint: 		
	incq %r13  		#jump over the character 's' in message
	popq %rsi 		#pop the next parameter in %rsi (should be a string address)
	movq $0, %r8    #move 0 to %r8, used for index for indirect memory addressing with displacement

#output a string character by character (just like we did before with printing the original message)
stringloop:
	movq (%rsi, %r8, 1), %r9 	#move to %r9 the value from (%rsi + 1*%r8)

	addq %r8, %rsi 				#add the index to %rsi

	#linux syscall for sys_write (the current character is already in %rsi)
	movq $1, %rax 				#1 in %rax for sys_write
	movq $1, %rdi  				#where to print (stdout)
	movq $1, %rdx 				#number of characters that should be printed (we always print only 1)
	syscall

	subq %r8, %rsi 				#subtract %r8 from %rsi to restore the original address of string
	incq %r8 					#increase %r8 by 1 to get to the next character in message

	cmpb $0, %r9b 				#if %r9 contains 0x00, then we reached the end of the string
	jne stringloop 				#if not, print the next character

	jmp continue 				#once we reached the end of the string, jump to continue to print the
								#next character in the original message (should be a space, as we
								#jumped over 2 characters, namely '%' and 's')

percentprint:
	incq %r13 				#jump over '%';
	pushq $37 				#push the ASCII code 37 of '%' to the stack
	leaq (%rsp), %rsi 		#load the effective address of '%' in %rsi
	movq $1, %rax 			#1 in %rax for sys_write
	movq $1, %rdi  			#where to print (stdout)
	movq $1, %rdx 			#number of characters that should be printed (we always print only 1)
	syscall
	addq $8, %rsp 			#move the stack pointer back to the place it was before pushing the '%' char
	jmp continue			#continue printing the next character in the original message

signed_digit: # we will first convert the negative value to a positive one, then we will just output a minus sign
	popq %rdi 				#pop the number in %rdi
	neg %rdi 				#compute the 2's complement of the negative number, therefore giving us the positive value
	pushq %rdi 				#push the number back to the stack 
	pushq $45 				#push the ASCII code 45 of '-' to the stack
	leaq (%rsp), %rsi 		#load the effective address of '-' in %rsi
	movq $1, %rax 			#1 in %rax for sys_write
	movq $1, %rdi  			#where to print (stdout)
	movq $1, %rdx 			#number of characters that should be printed (we always print only 1)
	addq $8, %rsp 			#move the stack pointer back to the place it was before pushing the '-' char
	syscall 				#after we output the minus sign, continue printing the number

digitchar: # number in %rdi , number of digits in %rbx
	incq %r13  				#jump over the character 'u' or 'd' in message
	movq $0, %rbx 			#move 0 in %rbx (number of digits we are going to print, initial value 0)
	popq %rdi 				#pop the number in %rdi
	
	divide: 				#we are going to push to the stack every digit of the number, then output digit by digit
		movq $0, %rdx 		#clear %rdx before division
 		movq $10, %rsi 		#division by 10 in %rsi
 		movq %rdi, %rax  	#move the number to %rax for division
 		divq %rsi 			#divide %rax:%rsi (number/10) (remainder is stored in rdx)
 		movq %rax, %rdi 	#copy the result to %rdi
 		addq $48, %rdx 		#add 48 to the remainder in %rdx (48 ASCII code for '0')
 		pushq %rdx 			#push %rdx to the stack for printing later
 		incq %rbx 			#increase %rbx by 1 (the number of digits we have)
 		cmpq $0, %rax 		#compare if we still have digits left in the number %rax
 		jne divide 			#if we still have, divide again. Once %rax is 0, we can start printing the number

 	printingnr: 			#we will print digit by digit from the stack
 		leaq (%rsp), %rsi 	#load effective address of a digit to %rsi
		movq $1, %rax 		#1 in %rax for sys_write
		movq $1, %rdi  		#where to print (stdout)
		movq $1, %rdx 		#number of characters that should be printed (we always print only 1)
		syscall
		decq %rbx			#decrease %rbx by 1 (number of digits left to print)
		addq $8, %rsp 		#move the stack pointer to the next digit

		cmpq $0, %rbx 		#compare if there are digits left to be printed
		jne printingnr 		#if yes, print the next digit
	jmp continue 		#once the printing of the number finished, continue printing the original message

main:
	pushq %rbp 				# push the base pointer (and align the stack)
	movq %rsp, %rbp			# copy stack pointer value to base pointer

	#optional arguments, used for format specifier, values can be changed or omitted if not needed(comment the lines)
	movq $string2, %rdx  	#%s test value
	movq $848, %rcx  		#%u test value
	movq $string, %r8 		#%s test value
	movq $-42, %r9 			#%d test value
	pushq $-123472941  		#additional argument in stack
	pushq $1727  			#additional argument in stack
	pushq $string2  
	//pushq $9292
	//pushq $123
    
    movq $3, %rsi  			#number of additional parameteres in stack, second parameter for my_printf
	movq $message, %rdi  	#first parameter, message in %rdi
	call my_printf			#call myprintf, takes 2 arguments, message format in %rdi and number of 
							#additional arguments in stack in %rsi (can be 0 or more based on how many
							#format specifiers are provided in message)

	popq %rbp				# restore base pointer location 
	movq $0, %rdi			# load program exit code
	call exit				# exit the program

