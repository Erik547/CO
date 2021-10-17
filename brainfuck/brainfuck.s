.data
cells: .skip 30000

.text
format_str: .asciz "We should be executing the following code:\n%s"

.global brainfuck

# Your brainfuck subroutine will receive one argument:
# a zero termianted string containing the code to execute.
brainfuck:
	pushq %rbp
	movq %rsp, %rbp

	movq %rdi, %rbx

//rbx - brainfuck code
//r12 - memory pointer for code execution
//r13 - current memory cell

 	movq $0, %r12
	movq $cells, %r14

loop:
	movb (%rbx, %r12, 1), %r13b

	cmpb $43, %r13b
	je increment_memory_cell   #  +

	cmpb $45, %r13b
	je decrement_memory_cell  # - 

 	cmpb $62, %r13b
	je move_pointer_right   #  >

	cmpb $60, %r13b
	je move_pointer_left   #  <

	cmpb $91, %r13b
	je loop_start    #   jump over ] if pointer is zero

	cmpb $93, %r13b
	je loop_end    #   jump back to [ if pointer is non-zero 

	cmpb $46, %r13b
	je output_character       # .

	cmpb $44, %r13b
	je input_character    #   ,

continue:

	incq %r12

	cmpb $0, %r13b
	jne loop

	jmp end

move_pointer_right:
	addq $1, %r14
	jmp continue

move_pointer_left:
	subq $1, %r14
	jmp continue

increment_memory_cell:
	cmpb $255, (%r14)
	je overflow
	incb (%r14)
	jmp continue
overflow:
	movb $0, (%r14)
	jmp continue

decrement_memory_cell:
	cmpb $0, (%r14)
	je underflow
	decb (%r14)
	jmp continue
underflow:
	movb $255, (%r14)
	jmp continue

input_character:
	movq $0, %rax
	movq $0, %rdi 
	movq %r14, %rsi 
	movq $1, %rdx
	syscall
	jmp continue 

output_character:
	movq $1, %rax
	movq $1, %rdi 
	movq %r14, %rsi 
	movq $1, %rdx
	syscall
	jmp continue 

loop_start:
	cmpb $0, (%r14)
	je jump_over_loop

loop_again:
	pushq %r12
	jmp continue

loop_end:
	cmpb $0, (%r14)
	je endloop
	popq %r12
	jmp loop_again

endloop:
	addq $8, %rsp
	jmp continue


jump_over_loop:
	movq $1, %r15 
	incq %r12
jump:
	movb (%rbx, %r12, 1), %r13b

	cmpb $91, %r13b
	je break1
	
	cmpb $93, %r13b
	je break2
	jmp nextbreak

break1:
	incq %r15
	jmp nextbreak
break2:
	decq %r15

nextbreak:
	incq %r12

	cmpb $0, %r15b
	jne jump

	decq %r12
	jmp continue

end:
	movq %rbp, %rsp
	popq %rbp
	ret
