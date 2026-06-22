BITS 64
section .text
    global ft_putstr
	extern ft_strlen

ft_putstr:
    push rbx
    mov rbx, rdi
    call ft_strlen
    mov rdx, rax
    mov rsi, rbx
    mov rdi, 1
    mov rax, 1
    syscall
    pop rbx
    ret