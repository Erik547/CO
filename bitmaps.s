.data
message: .skip 3072 #reserve 3072 bytes of memory (for message)
barcode: .skip 3072 #reserve 3072 bytes of memory (for barcode)
xored: .skip 3072 #reserve 3072 bytes of memory (for xored)
decoded_message: .skip 3072 #reserve 3072 bytes of memory (for decoded_message)
todecrypt: .skip 3126 #reserve 3072 bytes of memory (for todecrypt, the contents of the file we will read)
header: .skip 54 #reserve 54 bytes of memory (for header)

filename: .asciz "barcode.bmp" #filename
filedesc: .quad 0 #file descriptor

.text
text: .asciz "The quick brown fox jumps over the lazy dog" #message we will encrypt
leadtail: .asciz "8C4S2E414480" #lead and tail we will apply to the message

inputstr: .asciz "Please choose between:\n1.Encode\n2.Decode\nInput:" #user input string
byebye: .asciz "WRONG ARGUMENT bruh\n" #wrong argument error string
encode_done: .asciz "Encoding done\n" #encoding done string
newline: .asciz "\n" #newline string
nr: .asciz "%ld" #number string

.global main

#copy the leadtail to memory
#r12 - address for $leadtail string
#r13 - current index in $leadtail
#r14 - character at the current index in $leadtail
#rbx - pointer to current location in $message
#return - rbx
lead_trail:
	pushq %rbp 			# push the base pointer (and align the stack)
	movq %rsp, %rbp		# copy stack pointer value to base pointer

	movq %rsi, %rbx     # copy the value of %rsi ($message) to %r12
	movq $0, %r13 		# clear %r13
	movq %rdi, %r12 	# copy the value of %rdi ($leadtail) to %r12
	movq $0, %rdi 		# clear %rdi

lead_tail_loop: #accessing memory with displacement:
	movq (%r12, %r13, 1), %r14 #move to %r14 the value from (%r12 + 1*%r13)
	#we are going to alternate between saving a number to memory or saving the
	#ASCII code of a character to the memory (8C4S in memory would be 8 67 4 83)
	#this is done by %rdi, when it's 1, save an ASCII code, when it's 0, save a number
	cmpq $1, %rdi 		#compare if 1 is in %rdi
	je normalchar 		#if yes, jump to normalchar (save the ASCII code to memory)

numberchar: 			#else, we save a number to memory
	subb $48, %r14b 	#subtract 48 from the number in %r14b, 48 is the ASCII code for '0'
	incq %rdi 			#increase %rdi by 1, meaning the next character is going to be a normal character
	jmp cont 			#jump to cont
normalchar: #we just decrease %rdi by 1, as a normal character already has an ASCII code.
	decq %rdi 			#next time, we are going to save a number.
cont:
	movb %r14b, (%rbx) 	#move the value from %r14b to the memory at %rbx (.data $message)
	incq %rbx 			#increase %rbx by 1 to get to the next memory byte

	incq %r13 			#increase %r13 by 1 to get to the next character in $leadtail

	movq (%r12, %r13, 1), %r14  #move to %r14 the value from (%r12 + 1*%r13)
								#to verify if we are at the end of $leadtail
	cmpb $0, %r14b 				#compare if %r14b is 0
	jne lead_tail_loop 			#if not, continue the lead tail loop

	movq %rbx, %rax 		#return the value of the pointer %rbx($message)
							#(save the current position in $message, required by other subroutines)
	movq %rbp, %rsp 		#clear the local variables from stack 
	popq %rbp				#restore base pointer location
	ret 					#return to main

#encryption subroutine, used to encrypt $text in RLE-8
#r12 - adress of $text
#r13 - current index in $text
#r14 - character at the current index in $text
#rbx - pointer to current location in $message
#return - rbx
encrypt_message:
	pushq %rbp 			# push the base pointer (and align the stack)
	movq %rsp, %rbp		# copy stack pointer value to base pointer

	movq %rsi, %rbx 
	movq %rdi, %r12 	#move the value of %rdi to %r12 ($text)
	movq $0, %r13 		#clear %r13

nextchar:
	movq (%r12, %r13, 1), %r14 #move to %r14 the value from (%r12 + 1*%r13)

	movq $1, %r15 		#set %r15 to 1 (number of times the character is repeated, initially 1)

	addq %r13, %r12 	#add %r13 to %r12 to get the character with displacement

testchar: #check if the next character is the same as the current character
	incq %r12  			#increase %r12 by 1 to get to the next character in memory
	cmpb (%r12), %r14b 	#check if the next character(%r12) is the same as the current character
	je samechar 		#if yes, jump to samechar
	jmp save_encrypt_tomem 	#else, jump to save_encrypt_tomem

samechar:
	incq %r15 		#increase %r15 by 1 (number of times the character is repeated)
	jmp testchar 	#jump to testchar to test again

save_encrypt_tomem: #save the number of times the character appears and the character to the memory

	movb %r15b, (%rbx) #move the number of times the character appears to the value at location %rbx
	incq %rbx 		   #increase %rbx by 1 to get to the next memory location
 
	subq %r15, %r12 	#subtract %r15 from %r12 to get the initial character that was counted
	subq %r13, %r12 	#also subtract %r13 from %r12 to get to the start of the message

	addq %r15, %r13 	#add %r15 to %r13 to jump over the same characters in $text

	movb %r14b, (%rbx) 	#move the ASCII code of the character to memory at location %rbx
	incq %rbx 			#increase %rbx by 1 to get to the next memory location

	movq (%r12, %r13, 1), %r14 #move to %r14 the value from (%r12 + 1*%r13) to verify if we are at the end of $text

	cmpb $0, %r14b 		#compare if %r14b is 0
	jne nextchar		#if not, jump to nextchar and continue the loop

	movq %rbx, %rax 		#return the value of the pointer %rbx($message)
	movq %rbp, %rsp 		#clear the local variables from stack 
	popq %rbp				#restore base pointer location
	ret 					#return to main
#create a 32x32 barcode pattern in memory (RGB, but we need to use BGR because of endianess)
#we are going to move 1 byte at a time in memory (sometimes even more if it's repeating)
#r12 - address for $barcode string
#r13 - used for loops when a lot of the same data needs to be saved (eg. 8 white rgb memory cells)
#r14 - used to count how many times the pattern has been saved (we require 32)
barcode_mem:
	pushq %rbp
	movq %rsp, %rbp

	movq $0, %r13 		#clear %r13
	movq %rdi, %r12 	#move the value of %rdi to %r12 ($barcode)
	movq $0, %r14 		#clear %r14
white1: #create 8 white BGR blocks (3 bytes per block)
	movb $255, (%r12) 	#move 1 byte (255) to memory at location %r12
	incq %r12 			#increase %r12 by 1 to get to the next memory location
	movb $255, (%r12) 	#move 1 byte (255) to memory at location %r12
	incq %r12 			#increase %r12 by 1 to get to the next memory location
	movb $255, (%r12) 	#move 1 byte (255) to memory at location %r12
	incq %r12 			#increase %r12 by 1 to get to the next memory location
	incq %r13 			#increase %r13 by 1
	cmpb $8, %r13b 		#check if %r13 is 8
	jne white1 			#if not, repeat white1
	movq $0, %r13 		#else, clear %r13 and continue
black1: #create 8 black BGR blocks (3 bytes per block)
	movb $0, (%r12) 	#move 1 byte (0) to memory at location %r12
	incq %r12 			#increase %r12 by 1 to get to the next memory location
	movb $0, (%r12) 	#move 1 byte (0) to memory at location %r12
	incq %r12 			#increase %r12 by 1 to get to the next memory location
	movb $0, (%r12) 	#move 1 byte (0) to memory at location %r12
	incq %r12 			#increase %r12 by 1 to get to the next memory location
	incq %r13 			#increase %r13 by 1
	cmpb $8, %r13b 		#check if %r13 is 8
	jne black1 			#if not, repeat black1
	movq $0, %r13 		#else, clear %r13 and continue
white2: #create 4 white BGR blocks (3 bytes per block)
	movb $255, (%r12) 	#move 1 byte (255) to memory at location %r12
	incq %r12 			#increase %r12 by 1 to get to the next memory location
	movb $255, (%r12) 	#move 1 byte (255) to memory at location %r12
	incq %r12 			#increase %r12 by 1 to get to the next memory location
	movb $255, (%r12) 	#move 1 byte (255) to memory at location %r12
	incq %r12 			#increase %r12 by 1 to get to the next memory location
	incq %r13 			#increase %r13 by 1
	cmpb $4, %r13b 		#check if %r13 is 8
	jne white2 			#if not, repeat white2
	movq $0, %r13 		#else, clear %r13 and continue
black2: #create 4 black BGR blocks (3 bytes per block)
	movb $0, (%r12) 	#move 1 byte (0) to memory at location %r12
	incq %r12 			#increase %r12 by 1 to get to the next memory location
	movb $0, (%r12) 	#move 1 byte (0) to memory at location %r12
	incq %r12 			#increase %r12 by 1 to get to the next memory location
	movb $0, (%r12) 	#move 1 byte (0) to memory at location %r12
	incq %r12 			#increase %r12 by 1 to get to the next memory location
	incq %r13 			#increase %r13 by 1
	cmpb $4, %r13b 		#check if %r13 is 8
	jne black2 			#if not, repeat black2
	movq $0, %r13 		#else, clear %r13 and continue
white3: #create 2 white BGR blocks (3 bytes per block)
	movb $255, (%r12) 	#move 1 byte (255) to memory at location %r12
	incq %r12 			#increase %r12 by 1 to get to the next memory location
	movb $255, (%r12) 	#move 1 byte (255) to memory at location %r12
	incq %r12 			#increase %r12 by 1 to get to the next memory location
	movb $255, (%r12) 	#move 1 byte (255) to memory at location %r12
	incq %r12 			#increase %r12 by 1 to get to the next memory location
	incq %r13 			#increase %r13 by 1
	cmpb $2, %r13b 		#check if %r13 is 8
	jne white3 			#if not, repeat white3
	movq $0, %r13 		#else, clear %r13 and continue
black3: #create 3 black BGR blocks (3 bytes per block)
	movb $0, (%r12) 	#move 1 byte (0) to memory at location %r12
	incq %r12 			#increase %r12 by 1 to get to the next memory location
	movb $0, (%r12) 	#move 1 byte (0) to memory at location %r12
	incq %r12 			#increase %r12 by 1 to get to the next memory location
	movb $0, (%r12) 	#move 1 byte (0) to memory at location %r12
	incq %r12 			#increase %r12 by 1 to get to the next memory location
	incq %r13 			#increase %r13 by 1
	cmpb $3, %r13b 		#check if %r13 is 8
	jne black3 			#if not, repeat black3
	movq $0, %r13 		#else, clear %r13 and continue
	#move 2 more white BGR blocks and 1 final red BGR block
	movb $255, (%r12) 	#move 1 byte (255) to memory at location %r12
	incq %r12 			#increase %r12 by 1 to get to the next memory location
	movb $255, (%r12) 	#move 1 byte (255) to memory at location %r12
	incq %r12 			#increase %r12 by 1 to get to the next memory location
	movb $255, (%r12) 	#move 1 byte (255) to memory at location %r12
	incq %r12 			#increase %r12 by 1 to get to the next memory location
	movb $255, (%r12) 	#move 1 byte (255) to memory at location %r12
	incq %r12 			#increase %r12 by 1 to get to the next memory location
	movb $255, (%r12) 	#move 1 byte (255) to memory at location %r12
	incq %r12 			#increase %r12 by 1 to get to the next memory location
	movb $255, (%r12) 	#move 1 byte (255) to memory at location %r12
	incq %r12 			#increase %r12 by 1 to get to the next memory location
	movb $0, (%r12)  	#move 1 byte (0) to memory at location %r12
	incq %r12			#increase %r12 by 1 to get to the next memory location
	movb $0, (%r12)		#move 1 byte (0) to memory at location %r12
	incq %r12			#increase %r12 by 1 to get to the next memory location
	movb $255, (%r12)  	#move 1 byte (255) to memory at location %r12
	incq %r12			#increase %r12 by 1 to get to the next memory location
	incq %r14 			#increase %r14 by 1
	cmpb $32, %r14b 	#check if %r14 is 32
	jne white1 			#if not, continue saving the pattern

	movq %rbp, %rsp 		#clear the local variables from stack 
	popq %rbp				#restore base pointer location
	ret 					#return to main


#copy the barcode pattern to $xored in memory
#r12 - adress of $barcode
#r13 - adress of $xored
#r14 - number of memory blocks to be saved (32x32x3 = 3072)
barcode_to_xor_memory:
	pushq %rbp 			# push the base pointer (and align the stack)
	movq %rsp, %rbp		# copy stack pointer value to base pointer

	movq %rdi, %r12 	# move the value of %rdi to %r12 ($barcode)
	movq %rsi, %r13 	# move the value of %rsi to %r13 ($xored)
	movq $0, %r14 		#clear %r14
	movq $0, %rsi 		#clear %rsi
barcode_to_xor_memory_loop:
	movb (%r12), %sil 	#move the value (1 byte) at location %r12 to %rsi 
	movb %sil, (%r13) 	#move the value from %rsi to memory at location %r13

	incq %r12 			#increase %r12 by 1
	incq %r13 			#increase %r13 by 1
	incq %r14 			#increase %r14 by 1

	cmpq $3072, %r14 	#compare if %r14 is 3072
	jne barcode_to_xor_memory_loop 	#if not, continue copying

	movq %rbp, %rsp 		#clear the local variables from stack 
	popq %rbp				#restore base pointer location
	ret 					#return to main

#xor the values between $message and $barcode and save them to $xored
#r12 - adress of $message/$todecrypt
#r15 - adress of $barcode
#rdx - adress of $xored/$decoded_message
xoring:
	pushq %rbp 			# push the base pointer (and align the stack)
	movq %rsp, %rbp		# copy stack pointer value to base pointer

	movq $0, %r13 			#clear %r13
	movq %rdi, %r12 		# move the value of %rdi to %r12 ($message/$todecrypt)
	movq %rsi, %r15 		# move the value of %rsi to %r15 ($barcode)
xoringloop:
	movq (%r12, %r13, 1), %r14 #move to %r14 the value from (%r12 + 1*%r13)

	movq $0, %rdi 			#clear %rdi
	movb %r14b, %dil 		#move 1 byte(the character from $message/$todecrypt) from %r14 to %rdi

	movq (%r15, %r13, 1), %rbx #move to %rbx the value from (%r15 + 1*%r13)

	movq $0, %rsi 			#clear %rsi 
	movb %bl, %sil 			#move 1 byte (the character from $barcode) from %rbx to %rsi

	xor %rdi, %rsi 			#XOR %rdi and %rsi and save it to %rsi

	movb %sil, (%rdx) 		#move the value from %rsi to the memory at location %rdx
	addq $1, %rdx 			#increase %rdx by 1 to get to the next memory location

	incq %r13 				#increase %r12 by 1 to get to the next character

	movq (%r12, %r13, 1), %r14 	#move to %r14 the value from (%r12 + 1*%r13)

	cmpb $0, %r14b 			#compare if %r14b is 0
	jne xoringloop 			#if not, jump to xoringloop again to xor the next character
							##else, we reached the end of the message, return
	movq %rbp, %rsp		# clear local variables from stack
	popq %rbp			# restore base pointer location
	ret 				# return

#create the header of the bmp file, as specified in the lab manual
#r12 - address of $header
#r13 - used for loops when a lot of zeros need to be saved
# the 54 bytes of header should look like this: (in hex)
# 4d42 360c 0000 0000 0000 0036 0000 0028
# 0000 0020 0000 0020 0000 0001 0018 0000
# 0000 000c 0000 130b 0000 130b 0000 0000
# 0000 0000 0000
createheader:
	pushq %rbp 			# push the base pointer (and align the stack)
	movq %rsp, %rbp		# copy stack pointer value to base pointer
	movq %rdi, %r12
	movb $66, (%r12) 	#move 1 byte (66) to memory at location %r12
	incq %r12
	movb $77, (%r12) 	#move 1 byte (77) to memory at location %r12
	incq %r12
	movb $12, (%r12) 	#move 1 byte (12) to memory at location %r12
	incq %r12
	movb $54, (%r12)  	#move 1 byte (54) to memory at location %r12
	incq %r12
	movl $0, (%r12)  	#move 4 bytes (0) to memory at location %r12
	addq $4, %r12
	movw $0, (%r12) 	#move 2 bytes (0) to memory at location %r12
	addq $2, %r12
	movb $54, (%r12) 	#move 1 byte (54) to memory at location %r12
	incq %r12
	movw $0, (%r12) 	#move 2 bytes (0) to memory at location %r12
	addq $2, %r12 	
	movb $0, (%r12) 	#move 1 byte (0) to memory at location %r12
	incq %r12
	movb $40, (%r12) 	#move 1 byte (40) to memory at location %r12
	incq %r12
	movw $0, (%r12) 	#move 2 bytes (0) to memory at location %r12
	addq $2, %r12
	movb $0, (%r12) 	#move 1 byte (0) to memory at location %r12
	incq %r12
	movb $32, (%r12) 	#move 1 byte (32) to memory at location %r12
	incq %r12
	movw $0, (%r12) 	#move 2 bytes (0) to memory at location %r12
	addq $2, %r12
	movb $0, (%r12) 	#move 1 byte (0) to memory at location %r12
	incq %r12
	movb $32, (%r12) 	#move 1 byte (32) to memory at location %r12
	incq %r12
	movw $0, (%r12) 	#move 2 bytes (0) to memory at location %r12
	addq $2, %r12
	movb $0, (%r12) 	#move 1 byte (0) to memory at location %r12
	incq %r12
	movb $1, (%r12)	 	#move 1 byte (1) to memory at location %r12
	incq %r12
	movb $0, (%r12) 	#move 1 byte (0) to memory at location %r12
	incq %r12
	movb $24, (%r12) 	#move 1 byte (24) to memory at location %r12
	incq %r12
	movl $0, (%r12)  	#move 4 bytes (0) to memory at location %r12
	addq $4, %r12
	movb $0, (%r12) 	#move 1 byte (0) to memory at location %r12
	incq %r12
	movb $12, (%r12) 	#move 1 byte (12) to memory at location %r12
	incq %r12
	movw $0, (%r12)  	#move 2 bytes (0) to memory at location %r12
	addq $2, %r12
	movb $0, (%r12) 	#move 1 byte (0) to memory at location %r12
	incq %r12
	movb $11, (%r12) 	#move 1 byte (11) to memory at location %r12
	incq %r12
	movb $19, (%r12) 	#move 1 byte (19) to memory at location %r12
	incq %r12
	movw $0, (%r12)  	#move 2 bytes (0) to memory at location %r12
	addq $2, %r12
	movb $11, (%r12) 	#move 1 byte (11) to memory at location %r12
	incq %r12
	movb $19, (%r12) 	#move 1 byte (19) to memory at location %r12
	incq %r12
	movw $0, (%r12)  	#move 2 bytes (0) to memory at location %r12
	addq $2, %r12
	movq $0, (%r12)  	#move 8 bytes (0) to memory at location %r12
	addq $8, %r12 
	
	movq %rbp, %rsp		# clear local variables from stack
	popq %rbp			# restore base pointer location
	ret 				# return


#writes the content of $header and $xored to barcode.bmp file
#https://stackoverflow.com/c/tud-cs/questions/1844
#https://stackoverflow.com/c/tud-cs/questions/2038/2041#2041
#https://www.tutorialspoint.com/assembly_programming/assembly_file_management.htm
#rdi - $filename
#rsi - $header
#rdx - $xored
writefile:
	pushq %rbp 			# push the base pointer (and align the stack)
	movq %rsp, %rbp		# copy stack pointer value to base pointer

	pushq %rdi 			# push %rdi to the stack
	pushq %rsi 			# push %rsi to the stack
	pushq %rdx 			# push %rdx to the stack

	movq $2, %rax 			# use the 'open' syscall
	movq -8(%rbp), %rdi 	# first argument is the filename
	movq $0101, %rsi 		# set flags: O_CREAT | O_WRONLY
	syscall 				# create and open the file (write-only)
	movq %rax, filedesc 	# move %rax (return value from syscall) to file descriptor

	movq $1, %rax  			# use the 'write' syscall
	movq filedesc, %rdi 	#move the file descriptor to %rdi
	movq -16(%rbp), %rsi 	#move $header to %rsi
	movq $54, %rdx 			#move 54 to %rdx (54 bytes will be written to the file)
	syscall

	movq $1, %rax  			# use the 'write' syscall
	movq filedesc, %rdi 	#move the file descriptor to %rdi
	movq -24(%rbp), %rsi 	#move $xored to %rsi
	movq $3072, %rdx 		#move 3072 to %rdx (3072 bytes will be written to the file)
	syscall

	movq $3, %rax  			# use the 'close' syscall
	movq filedesc, %rdi 	#move the file descriptor to %rdi
	syscall

	movq %rbp, %rsp		# clear local variables from stack
	popq %rbp			# restore base pointer location
	ret 				# return

#open barcode.bmp file and save its contents to memory
#rdi - $filename
#rsi - $todecrypt
openfile:
	pushq %rbp
	movq %rsp, %rbp

	pushq %rdi 			# push %rdi to the stack
	pushq %rsi 			# push %rsi to the stack

	movq $2, %rax 			# use the 'open' syscall
	movq -8(%rbp), %rdi 	# first argument is the filename
	movq $00, %rsi 			# set flags O_RONLY
	syscall 				# open the file (read only)
	movq %rax, filedesc 	# move %rax (return value from syscall) to file descriptor

	movq $0, %rax  			# use the 'read' syscall
	movq filedesc, %rdi 	#move the file descriptor to %rdi
	movq -16(%rbp), %rsi 	#move $todecrypt to %rsi
	movq $3126, %rdx 		#move 3126 to %rdx (we will read 3126 bytes from the file)
	syscall

	movq $3, %rax  			# use the 'close' syscall
	movq filedesc, %rdi 	#move the file descriptor to %rdi
	syscall

	movq %rbp, %rsp		# clear local variables from stack
	popq %rbp			# restore base pointer location
	ret 				# return

#remove last 12 bytes (the length of leadtail) from the message in memory
#r12 - $decoded_message (note: not yet decoded, we just remove the unnecessary leadtail)
removelastbytes:
	pushq %rbp 			# push the base pointer (and align the stack)
	movq %rsp, %rbp		# copy stack pointer value to base pointer
	movq %rdi, %r12 	# move %rdi ($decoded_message) to %r12
	movq $0, %r13 		# clear %r13

bytecount: 	#count the number of non-zero bytes (the length of the message)
	movq (%r12, %r13, 1), %r14  #move to %r14 the value from (%r12 + 1*%r13)

	incq %r13 			#increase %r13 by 1

	cmpb $0, %r14b 		#check if %r14 is 0 (end of string)
	jne bytecount 		#if not, continue counting
	decq %r13 			#once done, decrease %r13 by 1
	addq %r13, %r12 	#add %r13 to %r12
	subq $12, %r12 		#substract 12 from %r12 (length of $leadtail)
	movq $0, %r13 		#clear %r13
	#now %r12 is at the end of the message, before the tail
zero:
	movq (%r12, %r13, 1), %r14 #move to %r14 the value from (%r12 + 1*%r13)
	cmpb $0, %r14b 		#compare if current memory cell is zero
	jne clearcell 		#if not, clear the cell (put a 0 in it)
						#this will fill 12 cells containing the leadtail with 0
	movq %rbp, %rsp		# clear local variables from stack
	popq %rbp			# restore base pointer location 
	ret
	
clearcell:
	addq %r13, %r12 	#add %r13 to %r12 to get to the current memory cell
	movb $0, (%r12) 	#move 0 to the memory location at %r12
	subq %r13, %r12 	#subtract %r13 from %r12 to get back to the start of %r12
	incq %r13 			#increase %r13 by 1
	jmp zero 			#jump back to zero


#decode the message in $decoded_message
#r12 - address of $decoded_message
#r13 - current index in $decoded_message
#r14 - character at the current index in $decoded_message
decode:
	# prologue
	pushq %rbp 			# push the base pointer (and align the stack)
	movq %rsp, %rbp		# copy stack pointer value to base pointer

	#clear all callee-saved registers
	movq $0, %r12 		
	movq $0, %r13
	movq $0, %r14
	movq $0, %r15
	movq $0, %rbx

	call removelastbytes #call removelastbytes to remove the tail from the message

decode_continue:
	movq %rdi, %r12
	addq $12, %r12 		#add 12 to %r12 to jump over the lead
	movq $0, %r13 		#clear %r13

nextbyte:
	movq (%r12, %r13, 1), %r14 	#move to %r14 the value from (%r12 + 1*%r13)

	addq %r13, %r12 		#add %r13 to %r12 to get to the current character 

	movb (%r12), %r15b 		#move the value from memory at %r12 to %r15
							#this will be the number of times we should print the character
	addq $1, %r12 			#add 1 to %r12 to get to the character that should be printed

decode_loop:
	movq $1, %rax 		#1 in %rax for sys_write
	movq $1, %rdi 		#where to print (stdout)
	movq %r12, %rsi 	#character that should be printed in %rsi
	movq $1, %rdx 		#number of characters that should be printed (we always print only 1)
	syscall

	decq %r15 			#decrease the number of times the character needs to be printed by 1
	cmpq $0, %r15 		#check if %r15 is 0
	jne decode_loop 	#if not, print the character again

	subq %r13, %r12 	#subtract %r13 from %r12 to get to the start of the message
	subq $1, %r12 		#also subtract 1 from %r12 (we added 1 earlier)

	addq $2, %r13 		#add 2 to %r13 to get to the next number and character

	movq (%r12, %r13, 1), %r14 	#move to %r14 the value from (%r12 + 1*%r13)
	cmpb $0, %r14b	#check if %r14 is 0 (end of message)
	jne nextbyte 	#if not, jump to nextbyte and continue decoding

	# epilogue
	movq %rbp, %rsp		# clear local variables from stack
	popq %rbp			# restore base pointer location 
	ret 				#return 

main:
	pushq %rbp 			# push the base pointer (and align the stack)
	movq %rsp, %rbp		# copy stack pointer value to base pointer

	#push the values of the calle-saved registers to the stack
	pushq %r12  			#push %r12
	pushq %r13				#push %r13
	pushq %r14 				#push %r14
	pushq %r15 				#push %r15
	pushq %rbx 				#push %rbx

	call input 	#call input for user input (1.encode/2.decode)

	#restore the values of the calle-saved registers from the stack
	popq %rbx 				#pop %rbx
	popq %r15 				#pop %r15
	popq %r14  				#pop %r14
	popq %r13				#pop %r13
	popq %r12 				#pop %r12

	popq %rbp			# restore base pointer location 
	movq $0, %rdi		# load program exit code
	call exit			# exit the program

input:
	pushq %rbp 			# push the base pointer (and align the stack)
	movq %rsp, %rbp		# copy stack pointer value to base pointer

	#call 2 subroutines that both encoding and decoding will need
	movq $barcode, %rdi
  	call barcode_mem 			#call this to save the barcode pattern to the memory .data $barcode
  	
  	movq $xored, %rsi
  	movq $barcode, %rdi
  	call barcode_to_xor_memory  #call this to copy the barcode patther to .data $xored
  	
	movq $0, %rax  			#no vector registers for printf
	movq $inputstr, %rdi   	#output format in %rdi
	call printf				#print the input string (choose option 1 or 2)

	subq $8, %rsp 			#reserve space in stack for input
	leaq -8(%rbp), %rsi     #first parameter at address of reserved space
	movq $nr, %rdi          #input format string
	movq $0, %rax 			#no vector registers for scanf
	call scanf 				#call scanf for user input

	popq %rsi 				#pop the value from stack to %rsi (option number)
	addq $8, %rsp 			#clean the stack

	cmpq $1, %rsi 			#compare if 1 is the selected option in %rsi
	je encode_start 		#if yes, start encoding the message

	cmpq $2, %rsi 			#compare if 2 is the selected option in %rsi 
	je decode_start 		#if yes, start decoding the barcode.bmp file
	jne wrong_input_argument_bruh  #else, wrong input has been entered and close the program

	movq %rbp, %rsp 		#clear the local variables from stack 
	popq %rbp				#restore base pointer location
	ret 					#return to main

wrong_input_argument_bruh:
	movq $0, %rax   		#no vector registers for printf
	movq $byebye, %rdi 		#output format string
	call printf 			#print the byebye string
	movq %rbp, %rsp 		#clear the local variables from stack 
	popq %rbp				#restore base pointer location
	ret 					#return to main

encode_start:
	movq $message, %rsi 	#move $message to %rsi (second argument for call)
	movq $leadtail, %rdi 	#move $leadtail to %rsi (first argument for call)
	call lead_trail 		#call lead_tail
	movq %rax, %rsi 		#move the return value to %rsi

	movq $text, %rdi 		#move $text to %rdi (first argument for call)
	call encrypt_message 	#call encrypt message
	movq %rax, %rsi 		#move the return value to %rsi

	movq $leadtail, %rdi 	#move $leadtail to %rdi (first argument for call)
	call lead_trail 		#call lead_tail

	movq $message, %rdi 	#move $message to %rdi (first argument for call)
	movq $barcode, %rsi 	#move $barcode to %rsi (second argument for call)
	movq $xored, %rdx 		#move $xored to %rdx (third argument for call)
	call xoring 			#call xoring

	movq $header, %rdi 		#move $header to %rdi (first argument for call)
	call createheader 		#call createheader

	movq $filename, %rdi 	#move $filename to %rdi (first argument for call)
	movq $header, %rsi 		#move $header to %rsi (second argument for call)
	movq $xored, %rdx 		#move $xored to %rdx (third argument for call)
	call writefile 			#call writefile

	movq $0, %rax 			 #no vector registers for printf
	movq $encode_done, %rdi  #output format string
	call printf 			 #print the encode_done string
	movq %rbp, %rsp 		 #clear the local variables from stack 
	popq %rbp				 #restore base pointer location
	ret 					 #return to main

decode_start:
	movq $filename, %rdi 		#move $filename to %rdi (first argument for call)
	movq $todecrypt, %rsi 		#move $todecrypt to %rsi (second argument for call)
	call openfile 				#call openfile

	movq $todecrypt, %rdi 		#move $filename to %rdi (first argument for call)
	movq $barcode, %rsi 		#move $barcode to %rsi (second argument for call)
	movq $decoded_message, %rdx #move $decoded_message to %rdx (third argument for call)
	addq $54, %rdi 				#add 54 to %rdi (jump over the header)
	call xoring 				#call xoring

	movq $decoded_message, %rdi #move $decoded_message to %rdi (first argument for call)
	call decode 				#call decode

	movq $0, %rax 			#no vector registers for printf
	movq $newline, %rdi 	#output format string
	call printf 			#print the newline string (for making the output more visible)
	movq %rbp, %rsp 		#clear the local variables from stack 
	popq %rbp				#restore base pointer location
	ret 					#return to main
