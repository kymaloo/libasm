BITS 64
section .text
    global ft_list_push_front
    extern malloc

ft_list_push_front:
    push rdi
    push rsi
    mov rdi, rsi
    call create_node
    test rax, rax
    je .error
    pop rsi
    pop rdi
    mov rdx, [rdi]
    mov [rax + 8], rdx
    mov [rdi], rax
    ret

.error:
    pop rsi
    pop rdi
    xor rax, rax
    ret

create_node:
    push rdi
    sub rsp, 8
    mov rdi, 16
    call malloc wrt ..plt
    add rsp, 8
    test rax, rax
    je .error2
    pop rdi
    mov [rax], rdi
    mov qword [rax + 8], 0
    ret

.error2:
    pop rdi
    xor rax, rax
    ret