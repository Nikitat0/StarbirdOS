    %macro rt_fn 1
    section .rt.%1 progbits alloc exec nowrite align=16
    global %1
%1:
    %endmacro
; ;
; ;
    rt_fn memset
    mov eax, esi
    mov rcx, rdx
    push rdi

    cmp ecx, 16
    jb .unaligned
    test edi, 0xf
    jnz .unaligned

    sub rsp, 16
    movaps [rsp], xmm0
    movd xmm0, esi
    punpcklbw xmm0, xmm0
    pshuflw xmm0, xmm0, 0
    pshufd xmm0, xmm0, 0

    and rdx, -16
.loop:
    sub rdx, 16
    movaps [rdi + rdx], xmm0
    jnz .loop

    movaps xmm0, [rsp]
    add rsp, 16

    add rdi, rcx
    and ecx, 0xf
    sub rdi, rcx

    .unaligned:
    rep stosb

    pop rax
    ret
; ;
; ;
    rt_fn memcpy
    mov rax, rdi
    mov rcx, rdx
    rep movsb
    ret
