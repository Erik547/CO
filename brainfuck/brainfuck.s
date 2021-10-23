.data
cells: .skip 30000 #reserve 30000 bytes of memory (brainfuck specification)

.text

.global brainfuck
		
# Your brainfuck subroutine will receive one argument:
# a zero termianted string containing the code to execute.
brainfuck:
	pushq %rbp				#push the base pointer
	movq %rsp, %rbp			#copy stack pointer value to base pointer

	#push the values of the calle-saved registers to the stack
	pushq %r12  			#push %r12
	pushq %r13				#push %r13
	pushq %r14 				#push %r14
	pushq %r15 				#push %r15
	pushq %rbx 				#push %rbx

	movq %rdi, %rbx 		#move the brainfuck code to %rbx register

#rbx - brainfuck code
#r12 - pointer to the current position in the brainfuck code
#r13 - current character in the brainfuck code
#r14 - pointer to the current memory cell in .data

 	movq $0, %r12 			#clear %r12 (start at the beginning of the bf code)
	movq $cells, %r14  		#memory cell address in %r14

loop: #using indirect memory addressing with displacement we parse the bf code character by character
	movb (%rbx, %r12, 1), %r13b  	#move 1 byte to %r13b, the value from (%rbx (bf code) + 1*%r12)

	cmpb $43, %r13b 				#compare if %r13b is ASCII code 43 '+'
	je increment_memory_cell   		#if yes, jump to increment_memory_cell

	cmpb $45, %r13b 				#compare if %r13b is ASCII code 45 '-'
	je decrement_memory_cell  		#if yes, jump to decrement_memory_cell

 	cmpb $62, %r13b 				#compare if %r13b is ASCII code 62 '>'
	je move_pointer_right   		#if yes, jump to move_pointer_right

	cmpb $60, %r13b 				#compare if %r13b is ASCII code 60 '<'
	je move_pointer_left   			#if yes, jump to move_pointer_left

	cmpb $91, %r13b 				#compare if %r13b is ASCII code 91, '['
	je loop_start    				#if yes, jump to loop_start (also jump over [ if current cell is zero)

	cmpb $93, %r13b 				#compare if %r13b is ASCII code 93, ']'
	je loop_end    					#if yes, jump to loop_end (also jump back to ] if current cell is non-zero)

	cmpb $46, %r13b					#compare if %r13b is ASCII code 46, '.'
	je output_character       		#if yes, jump to output_character

	cmpb $44, %r13b 				#compare if %r13b is ASCII code 44, ','
	je input_character    			#if yes, jump to input_character

continue:
	incq %r12 				#increase %r12 by 1 to get to the next character in the bf code

	cmpb $0, %r13b			#compare if the current character is 0x00 (end of file)
	jne loop 				#if not, loop again to the next character
	
	jmp end 				#if yes, jump to end

move_pointer_right: 		
	addq $1, %r14 			#increase %r14 by 1 to get to the next cell in .data
	jmp continue 			#continue to the next character in the bf code

move_pointer_left: 			
	subq $1, %r14 			#decrease %r14 by 1 to get to the previous cell in .data
	jmp continue 			#continue to the next character in the bf code

increment_memory_cell:
	incb (%r14) 			#increase the value of the memory cell where %r14 points to by 1
	jmp continue 			#continue to the next character in the bf code

decrement_memory_cell:
	decb (%r14) 			#decrease the value of the memory cell where %r14 points to by 1
	jmp continue 			#continue to the next character in the bf code

input_character:
	movq $0, %rax			#0 in %rax for sys_read
	movq $0, %rdi  			#0 in %rdi for stdin
	movq %r14, %rsi 		#the character should be stored at the address of %r14
	movq $1, %rdx 			#amount of characters that we should read
	syscall 
	jmp continue  			#continue to the next character in the bf code

output_character:
	movq $1, %rax 			#1 in %rax for sys_write
	movq $1, %rdi  			#where to print (stdout)
	movq %r14, %rsi  		#character that should be printed from %r14 to %rsi
	movq $1, %rdx			#number of characters that should be printed
	syscall
	jmp continue 			#continue to the next character in the bf code

loop_start:
	cmpb $0, (%r14) 		#compare if the value in the memory at %r14 is 0
	je jump_over_loop 		#if yes, jump over the loop [] completely (like an if statement)

loop_again:
	pushq %r12 				#if not, push the current position in the bf code to the stack ()
	jmp continue 			#continue the execution of the bf code (loop started)

loop_end:
	cmpb $0, (%r14) 		#check if the current value in the memory at %r14 is 0
	je endloop 				#if yes, end the loop
	popq %r12 				#if not, pop the last value of %r12(pushed when the loop started) 
							#back to %r12 (this will move the pointer %r12 back to the start of the loop, in order to loop again)

	jmp loop_again			#jump to loop again

endloop:
	addq $8, %rsp 			#clear the last value from the stack (last %r12 pushed)
	jmp continue 			#continue to the next character in the bf code


jump_over_loop: #this will count all loops (nested loops) and will jump over the matching ']'
	movq $1, %r15 			#move 1 to %r15	
	incq %r12 				#increase %r12 by 1 to get to the next character in the bf code

jump:
	movb (%rbx, %r12, 1), %r13b 	#move 1 byte to %r13b, the value from (%rbx (bf code) + 1*%r12)

	cmpb $91, %r13b 				#compare if %r13b is ASCII code 91, '['
	je break1 						#if yes, jump to break1
	
	cmpb $93, %r13b 				#compare if %r13b is ASCII code 93, ']'
	je break2 						#if yes, jump to break2
	jmp nextbreak  					#jump to nextbreak

break1:
	incq %r15 						#increase the value of %r15 by 1 (another loop inside the loop we are trying to jump over)
	jmp nextbreak 					#jump to nextbreak
break2:
	decq %r15 						#decrease the value of %r15 by 1 (previous loop ended)

nextbreak:
	incq %r12 						#increase %r12 by 1 to get to the next character in the bf code

	cmpb $0, %r15b 					#compare if %r15 is 0 (if all loops inside the loop we are trying to jump over have ended)
	jne jump 						#if not, go to jump again (we have not found the matching ']' yet)

	decq %r12 						#decrease %r12 by 1
	jmp continue 					#continue to the next character in the bf code

end:
	#restore the values of the calle-saved registers from the stack
	popq %rbx 				#pop %rbx
	popq %r15 				#pop %r15
	popq %r14  				#pop %r14
	popq %r13				#pop %r13
	popq %r12 				#pop %r12

	movq %rbp, %rsp         # clear the local variables from stack
	popq %rbp				# restore base pointer location 
	ret  					# return 
