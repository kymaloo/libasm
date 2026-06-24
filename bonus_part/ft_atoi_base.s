BITS 64
section .text
    global ft_atoi_base
    extern ft_strlen

ft_atoi_base:
    test rdi, rdi
    je .ret
    test rsi, rsi
    je .ret

    push rbx
    push r12
    push r13
    push r14
    push r15	; r15 = result
    mov rbx, rdi	; rbx = str
    mov r12, rsi	; r12 = base
    mov rdi, r12
    call is_valid_base
    test rax, rax
    je .error
    mov rdi, r12
    call ft_strlen
    mov r13, rax	; r13 = base_len
    mov r14, 1	; r14 = sign
    xor r15, r15

.skip_ws:
    movzx eax, byte [rbx]
    test al, al
    jz .error
    cmp al, ' '
    je .ws_next
    cmp al, 9               ; \t
    je .ws_next
    cmp al, 10              ; \n
    je .ws_next
    cmp al, 13              ; \r
    je .ws_next
    cmp al, 12              ; \f
    je .ws_next
    cmp al, 11              ; \v
    je .ws_next
    jmp .sign_loop
.ws_next:
    inc rbx
    jmp .skip_ws

.sign_loop:
    movzx eax, byte [rbx]
    cmp al, '+'
    je .sign_plus
    cmp al, '-'
    je .sign_moins
    jmp .convert
.sign_plus:
    inc rbx
    jmp .sign_loop
.sign_moins:
    neg r14
    inc rbx
    jmp .sign_loop

.convert:
    movzx eax, byte [rbx]
    test al, al
    jz .done
    mov rdi, r12
    movzx rsi, al
    call char_index
    cmp rax, -1
    je .done
    imul r15, r13           ; result *= base_len
    add r15, rax            ; result += digit
    inc rbx
    jmp .convert

.done:
    imul r15, r14
    mov rax, r15
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.error:
    xor rax, rax
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.ret:
    xor rax, rax
    ret

is_valid_base:
    push rbx
    push r12
    push r13
    mov r12, rdi
    call ft_strlen
    cmp rax, 2
    jl .invalid
    xor rbx, rbx

.base_loop:
    movzx eax, byte [r12 + rbx]
    test al, al
    jz .valid
    cmp al, '+'
    je .invalid
    cmp al, '-'
    je .invalid
    cmp al, ' '
    je .invalid
    cmp al, 9               ; \t
    je .invalid
    cmp al, 10              ; \n
    je .invalid
    cmp al, 13              ; \r
    je .invalid
    cmp al, 12              ; \f
    je .invalid
    cmp al, 11              ; \v
    je .invalid
    lea r13, [rbx + 1]

.cmp_loop:
    movzx ecx, byte [r12 + r13]
    test cl, cl
    jz .next_outer
    cmp al, cl
    je .invalid
    inc r13
    jmp .cmp_loop

.next_outer:
    inc rbx
    jmp .base_loop

.valid:
    mov eax, 1
    jmp .vb_end
.invalid:
    xor eax, eax
.vb_end:
    pop r13
    pop r12
    pop rbx
    ret

char_index:
    test rdi, rdi
    jz .not_found
    xor rax, rax
.loop:
    movzx ecx, byte [rdi + rax]
    test cl, cl
    jz .not_found
    cmp cl, sil
    je .found
    inc rax
    jmp .loop
.found:
    ret
.not_found:
    mov rax, -1
    ret