.data
message: .skip 30000
barcode: .skip 5000
xored: .skip 5000

todecrypt: .skip 5000

header: .skip 100

filename: .asciz "barcode.bmp"
filedesc: .quad 0

.text

text: .asciz "The quick brown fox jumps over the lazy dog"

leadtail: .asciz "8C4S2E414480"

nr: .asciz "%ld " 
char: .asciz "%c"

.global main

lead_trail:
	pushq %rbp
	movq %rsp, %rbp

	movq $0, %r13
	movq $leadtail, %r12
	movq $0, %rdi

ltloop:
	movq (%r12, %r13, 1), %r14

	movq $0, %r15
	movb %r14b, %r15b

	cmpq $1, %rdi
	je normalchar

numberchar:
	subb $48, %r15b
	incq %rdi
	jmp cont
normalchar:
	decq %rdi
cont:
	addb %r15b, (%rbx)
	incq %rbx

	incq %r13

	movq (%r12, %r13, 1), %r14

	cmpb $0, %r14b
	jne ltloop


	movq %rbp, %rsp
	popq %rbp 
	ret

encrypt_message:
	pushq %rbp
	movq %rsp, %rbp

	//movq $message, %rbx
	movq $text, %r12
	movq $0, %r13

nextchar:
	movq (%r12, %r13, 1), %r14

	movq $1, %r15

	addq %r13, %r12

testchar:
	incq %r12

	cmpb (%r12), %r14b
	je samechar
	jmp save_encrypt_tomem

samechar:
	incq %r15
	jmp testchar

save_encrypt_tomem:

	addb %r15b, (%rbx)
	incq %rbx

	subq %r15, %r12
	subq %r13, %r12

	addq %r15, %r13

	movq $0, %r15
	movb %r14b, %r15b

	addb %r15b, (%rbx)
	incq %rbx

	movq (%r12, %r13, 1), %r14

	cmpb $0, %r14b
	jne nextchar

	movq %rbp, %rsp
	popq %rbp
	ret

removelastbytes:
	movq $message, %r12
	movq $0, %r13

bytecount:
	movq (%r12, %r13, 1), %r14

	incq %r13

	cmpb $0, %r14b
	jne bytecount
	decq %r13
	addq %r13, %r12
	subq $12, %r12
	movq $0, %r13

zero:
	movq (%r12, %r13, 1), %r14
	cmpb $0, %r14b
	jne clearcell
	jmp decode_continue
	
clearcell:
	addq %r13, %r12
	movb $0, (%r12)
	subq %r13, %r12
	incq %r13
	jmp zero

decode:
	# prologue
	pushq %rbp 			# push the base pointer (and align the stack)
	movq %rsp, %rbp		# copy stack pointer value to base pointer
	jmp removelastbytes
decode_continue:
	movq $message, %r12
	addq $12, %r12
	movq $0, %r13

nextbyte:
	movq (%r12, %r13, 1), %r14

	addq %r13, %r12

	movb (%r12), %r15b
	
	addq $1, %r12

decode_loop:
	movq $1, %rax
	movq $1, %rdi
	movq %r12, %rsi
	movq $1, %rdx
	syscall

	decq %r15
	cmpq $0, %r15
	jne decode_loop

	subq %r13, %r12

	subq $1, %r12

	incb %r13b
	incb %r13b

	movq (%r12, %r13, 1), %r14

	cmpb $0, %r14b
	jne nextbyte

	# epilogue
	movq %rbp, %rsp		# clear local variables from stack
	popq %rbp			# restore base pointer location 
	ret



barcode_mem:
	pushq %rbp
	movq %rsp, %rbp
	movq $0, %r13
	movq $barcode, %r12
	movq $0, %r15
white1:
	movb $255, (%r12)
	incq %r12
	movb $255, (%r12)
	incq %r12
	movb $255, (%r12)
	incq %r12
	incq %r13
	cmpb $8, %r13b
	jne white1
	movq $0, %r13
black1:
	movb $0, (%r12)
	incq %r12
	movb $0, (%r12)
	incq %r12
	movb $0, (%r12)
	incq %r12
	incq %r13
	cmpb $8, %r13b
	jne black1
	movq $0, %r13
white2:
	movb $255, (%r12)
	incq %r12
	movb $255, (%r12)
	incq %r12
	movb $255, (%r12)
	incq %r12
	incq %r13
	cmpb $4, %r13b
	jne white2
	movq $0, %r13
black2:
	movb $0, (%r12)
	incq %r12
	movb $0, (%r12)
	incq %r12
	movb $0, (%r12)
	incq %r12
	incq %r13
	cmpb $4, %r13b
	jne black2
	movq $0, %r13
white3:
	movb $255, (%r12)
	incq %r12
	movb $255, (%r12)
	incq %r12
	movb $255, (%r12)
	incq %r12
	incq %r13
	cmpb $2, %r13b
	jne white3
	movq $0, %r13
black3:
	movb $0, (%r12)
	incq %r12
	movb $0, (%r12)
	incq %r12
	movb $0, (%r12)
	incq %r12
	incq %r13
	cmpb $3, %r13b
	jne black3
	movq $0, %r13
	movb $255, (%r12)
	incq %r12
	movb $255, (%r12)
	incq %r12
	movb $255, (%r12)
	incq %r12
	movb $255, (%r12)
	incq %r12
	movb $255, (%r12)
	incq %r12
	movb $255, (%r12)
	incq %r12
	movb $0, (%r12)  #red RGB
	incq %r12
	movb $0, (%r12)
	incq %r12
	movb $255, (%r12)
	incq %r12
	incq %r15
	cmpb $32, %r15b
	jne white1

	movb $3, (%r12)
	movq %rbp, %rsp
	popq %rbp
	ret

output_message_memory:
	pushq %rbp 			# push the base pointer (and align the stack)
	movq %rsp, %rbp		# copy stack pointer value to base pointer

	movq $0, %r13
	movq $todecrypt, %r12

output_message_memoryloop:
	movq (%r12, %r13, 1), %r14

/*	cmpb $9, %r14b
	jle nroutput
	jmp contoutput
nroutput:
	addb $48, %r14b */
contoutput:
	movq $0, %rsi
	movq $0, %rax
	movb %r14b, %sil
	movq $nr, %rdi
	call printf
	
	incq %r13

	movq (%r12, %r13, 1), %r14

	cmpb $3, %r14b
	jne output_message_memoryloop

	movq %rbp, %rsp		# clear local variables from stack
	popq %rbp			# restore base pointer location
	ret

xoring:
	# prologue
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	movq $0, %r13
	movq $message, %r12
	movq $barcode, %r15
	movq $barcode, %rdx
xoringloop:
	movq (%r12, %r13, 1), %r14

	movq $0, %rdi
	movb %r14b, %dil

	movq (%r15, %r13, 1), %rbx

	movq $0, %rsi
	movb %bl, %sil

	xor %rdi, %rsi

	addb %sil, (%rdx)
	addq $1, %rdx

	incq %r13

	movq (%r12, %r13, 1), %r14

	cmpb $0, %r14b
	jne xoringloop


	movq %rbp, %rsp		# clear local variables from stack
	popq %rbp			# restore base pointer location
	ret

createheader:
	movq $header, %r12
	movb $66, (%r12)
	incq %r12
	movb $77, (%r12)
	incq %r12
	movb $12, (%r12)
	incq %r12
	movb $54, (%r12)
	incq %r12
	movq $0, %r13 
headerzeros:
	movb $0, (%r12)
	incq %r12
	incq %r13
	cmpb $6, %r13b
	jne headerzeros
	movb $54, (%r12)
	incq %r12
	movb $0, (%r12)
	incq %r12
	movb $0, (%r12)
	incq %r12
	movb $0, (%r12)
	incq %r12
	movb $40, (%r12)
	incq %r12
	movb $0, (%r12)
	incq %r12
	movb $0, (%r12)
	incq %r12
	movb $0, (%r12)
	incq %r12
	movb $32, (%r12)
	incq %r12
	movb $0, (%r12)
	incq %r12
	movb $0, (%r12)
	incq %r12
	movb $0, (%r12)
	incq %r12
	movb $32, (%r12)
	incq %r12
	movb $0, (%r12)
	incq %r12
	movb $0, (%r12)
	incq %r12
	movb $0, (%r12)
	incq %r12
	movb $1, (%r12)
	incq %r12
	movb $0, (%r12)
	incq %r12
	movb $24, (%r12)
	incq %r12
	movb $0, (%r12)
	incq %r12
	movb $0, (%r12)
	incq %r12
	movb $0, (%r12)
	incq %r12
	movb $0, (%r12)
	incq %r12
	movb $0, (%r12)
	incq %r12
	movb $12, (%r12)
	incq %r12
	movb $0, (%r12)
	incq %r12
	movb $0, (%r12)
	incq %r12
	movb $0, (%r12)
	incq %r12
	movb $11, (%r12)
	incq %r12
	movb $19, (%r12)
	incq %r12
	movb $0, (%r12)
	incq %r12
	movb $0, (%r12)
	incq %r12
	movb $11, (%r12)
	incq %r12
	movb $19, (%r12)
	incq %r12
	movb $0, (%r12)
	incq %r12
	movb $0, (%r12)
	incq %r12
	movq $0, %r13 
headerzeros2:
	movb $0, (%r12)
	incq %r12
	incq %r13
	cmpb $8, %r13b
	jne headerzeros2
	jmp write

writefile:
	pushq %rbp
	movq %rsp, %rbp

	jmp createheader
write:
	movq $2, %rax
	movq $filename, %rdi
	movq $0101, %rsi
	syscall

	movq %rax, filedesc

	movq $1, %rax 
	movq filedesc, %rdi
	movq $header, %rsi
	movq $54, %rdx
	syscall

	movq $1, %rax 
	movq filedesc, %rdi
	movq $barcode, %rsi
	movq $3072, %rdx
	syscall


	movq $3, %rax 
	movq filedesc, %rdi
	syscall

	movq %rbp, %rsp
	popq %rbp
	ret

openfile:
	pushq %rbp
	movq %rsp, %rbp
	movq $2, %rax
	movq $filename, %rdi
	movq $0101, %rsi
	syscall

	movq %rax, filedesc

	movq $0, %rax 
	movq filedesc, %rdi
	movq $todecrypt, %rsi
	movq $54, %rdx
	syscall

	movq $3, %rax 
	movq filedesc, %rdi
	syscall

	movq %rbp, %rsp
	popq %rbp
	ret

main:
	pushq %rbp 			# push the base pointer (and align the stack)
	movq %rsp, %rbp		# copy stack pointer value to base pointer

	movq $message, %rbx
	call lead_trail
	call encrypt_message		# call decode
	call lead_trail
	//call decode
	call barcode_mem
	//call output_barcode
	call xoring
	//call output_message_memory
	call writefile
	call openfile
	//call output_message_memory

	popq %rbp			# restore base pointer location 
	movq $0, %rdi		# load program exit code
	call exit			# exit the program

