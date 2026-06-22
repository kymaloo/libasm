BITS 64
section .text
    global ft_strlen

ft_strlen:
    xor rcx, rcx
.loop:
    mov al, [rdi + rcx]
    test al, al
    je .done
    inc rcx
    jmp .loop
.done:
    mov rax, rcx
    ret