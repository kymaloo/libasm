BITS 64
section .text
    global ft_read
	extern __errno_location

ft_read:
	mov		rax, 0
	syscall
	test rax, rax
	jl .error
	ret	
.error:
	neg		rax
	mov		rdi, rax
	call	__errno_location
	mov		[rax], 	rdi
	mov		rax, -1
	ret