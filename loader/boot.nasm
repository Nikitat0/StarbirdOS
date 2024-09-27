    %ifdef DEMO
    %define PRINT
    %endif
    %ifndef IGNORE_ERROR
    %define MSG
    %endif
    %ifndef PATTERN_TEST
    %define MSG
    %endif
    %ifdef MSG
    %define PRINT
    %endif

    bits 16

    cli
    mov sp, 0xffff
    mov bp, 0x1000
    mov ss, bp
    sti
    shl bp, 1

    %ifdef MSG
    mov ds, bp
    push end
    %endif

    %ifndef IGNORE_ERROR
    lea si, [error_msg]
    %endif

    mov es, bp
    mov ax, 0x0202
    xor bx, bx
    xor cx, cx
    inc cx
    xor dh, dh
read_loop:
    int 0x13
    %ifndef IGNORE_ERROR
    jc print_msg
    %endif
    add cl, al ; add cl, 2
    cmp cl, 19
    jne .no_carry
    mov cl, 1
    inc dh
    test dh, 2
    jz .no_carry
    inc ch
    xor dh, dh
.no_carry:
    mov ah, 2
    add bp, 0x40
    mov es, bp
    cmp bp, 0x8000
    jne read_loop

    %ifdef DEMO
    mov si, 0x200
    call print
    %endif

    %ifdef PATTERN_TEST
    lea si, [failed_msg]
    mov bp, 0x2080
    mov ds, bp
pattern_test_loop:
    cmp bl, byte [bx]
    jne print_msg
    inc bl
    jnz pattern_test_loop
    add bp, 0x10
    mov ds, bp
    cmp bp, 0x8000
    jne pattern_test_loop

    lea si, [passed_msg]
    call print_msg
    %endif

end:
    jmp $ ; infinite loop

; si: offset of msg
; ax, si are volatile
print_msg:
    mov ax, 0x7c0
    mov ds, ax
    push si
    lea si, [crlf]
    call print
    pop si
    jmp print ; tail call

    %ifdef PRINT
; (ds:si): char* str
; ax, si are volatile
print:
    cld
    mov ah, 0xe
.loop:
    lodsb
    test al, al
    jz .return
    int 0x10
    jmp .loop
.return:
    ret
    %endif

    %ifdef MSG
crlf:
    db 0xd, 0xa, 0
    %endif

    %ifdef PATTERN_TEST
passed_msg:
    db "Pattern test is passed", 0
failed_msg:
    db "Pattern test is failed", 0
    %endif

    %ifndef IGNORE_ERROR
error_msg:
    db "An error occurred during reading of the image", 0
    %endif

    times 510-($-$$) db 0
    db 0x55, 0xaa
