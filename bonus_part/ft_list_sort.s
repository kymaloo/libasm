BITS 64
section .text
    global ft_list_sort

ft_list_sort:
    test rdi, rdi
    je .false

    push rbx
    push r12
    push r13
	push r14

    mov rbx, [rdi]      ; rbx = current node
    mov r12, rsi        ; r12 = cmp function (callee-saved, survives call)
	mov r14, [rdi]		; head

.loop:
    mov r13, [rbx + 8]  ; r13 = next node
    test r13, r13
    je .sorted          ; no next node → sorted

    mov rdi, [rbx]      ; arg1 = current->content
    mov rsi, [r13]      ; arg2 = next->content
    call r12            ; cmp(current, next)

    test rax, rax
    jg .swap     		; if cmp > 0, not sorted

    mov rbx, r13        ; advance: current = next
    jmp .loop


.swap:
	mov rdi, [rbx]
	mov rsi, [r13]
	mov [rbx], rsi
	mov [r13], rdi
	
	mov rbx, r14
	jmp .loop

.sorted:
	pop r14
    pop r13
    pop r12
    pop rbx
    ret

.false:
    ret