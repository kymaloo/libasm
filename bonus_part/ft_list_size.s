BITS 64
section .text
    global ft_list_size

ft_list_size:
	xor rcx, rcx
.loop:
	test rdi, rdi
	je .done
	inc rcx
	mov rdi, [rdi + 8]
	jmp .loop
.done:
	mov rax, rcx
	ret
