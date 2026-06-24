BITS 64
section .text
    global ft_strdup
	extern malloc
	extern ft_strlen
	extern ft_strcpy

ft_strdup:
	push rdi
	call ft_strlen
	inc rax
	mov rdi, rax
	call malloc wrt ..plt
	pop rsi
	test rax, rax
	je .error
	mov rdi, rax
	call ft_strcpy
	jmp .done

.error:
	ret

.done:
	ret