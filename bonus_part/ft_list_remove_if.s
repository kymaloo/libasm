BITS 64
section .text
    global ft_list_remove_if
	extern free

ft_list_remove_if:
    test    rdi, rdi
    je      .ret
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15

    mov     rbx, rdi        ; rbx = t_list **
    mov     r12, rsi        ; r12 = data
    mov     r13, rdx        ; r13 = cmp
    mov     r14, rcx        ; r14 = free_fct

.loop:
    mov     r15, [rbx]
    test    r15, r15
    je      .done

    mov     rdi, [r15]
    mov     rsi, r12
    call    r13
    test    rax, rax
    jne     .next

    mov     rdi, [r15]
    call    r14

    mov     rdi, [r15 + 8]
    mov     [rbx], rdi

    mov     rdi, r15
    call    free

    jmp     .loop

.next:
    lea     rbx, [r15 + 8]
    jmp     .loop

.done:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
.ret:
    ret