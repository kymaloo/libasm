BITS 64
section .text
    global ft_strcmp

ft_strcmp:
    xor rcx, rcx
.loop:
    movzx rax, byte [rdi + rcx]
    movzx rdx, byte [rsi + rcx]
    cmp rax, rdx
    jne .done
    test rax, rax
    jz .done
	test rdx, rdx
    jz .done
    inc rcx
    jmp .loop
.done:
    sub rax, rdx
    ret