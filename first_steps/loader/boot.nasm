    RETRY_COUNT equ 5

    %ifdef DEMO
    %define PRINT
    %define SET_DS
    %endif
    %ifdef REPORT_ERROR
    %define PRINT
    %define SET_DS
    %endif
    %ifdef PATTERN_TEST
    %define PRINT
    %endif

    bits 16

    cli
    xor sp, sp
    mov bp, 0x1000
    mov ss, bp
    sti
    shl bp, 1

    %ifdef REPORT_ERROR
    mov ax, 0x7c0
    mov ds, ax
    mov si, error_msg
    %endif

    mov es, bp
    xor bx, bx
    xor cx, cx
    inc cx
    xor dh, dh
read_loop:
    mov di, RETRY_COUNT
.retry:
    mov ax, 0x0202
    int 0x13
    jnc .success
    dec di
    jnz .retry
    %ifdef REPORT_ERROR
    call print
    %endif
    jmp end
.success:
    add cl, al ; add cl, 2
    cmp cl, 19
    jne .no_carry
    mov cl, 1
    add ch, dh
    xor dh, 1
.no_carry:
    add bp, 0x40
    mov es, bp
    cmp bp, 0x8000
    jne read_loop

    %ifdef SET_DS
    mov si, 0x2000
    mov ds, si
    %endif

    %ifdef DEMO
    mov si, 0x200
    call print
    %endif

    %ifdef DEMO
    %ifdef PATTERN_TEST
    mov si, crlf
    call print
    %endif
    %endif

    %ifdef PATTERN_TEST
    push end
    mov si, failed_msg
    mov bp, 0x2080
    mov es, bp
pattern_test_loop:
    cmp bl, byte es:[bx]
    jne print
    inc bl
    jnz pattern_test_loop
    add bp, 0x10
    mov es, bp
    cmp bp, 0x8000
    jne pattern_test_loop

    mov si, passed_msg
    jmp print
    %endif

end:
    jmp $ ; infinite loop

    %ifdef CODE_SIZE
    %assign CODE_SIZE $ - $$
    %warning Code size is CODE_SIZE
    %endif

    %ifdef PRINT
; Prints a zero-terminated string
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

    %ifdef DEMO
    %ifdef PATTERN_TEST
crlf:
    db 0xd, 0xa, 0
    %endif
    %endif

    %ifdef PATTERN_TEST
passed_msg:
    db "Pattern test is passed", 0xd, 0xa, 0
failed_msg:
    db "Pattern test is failed", 0xd, 0xa, 0
    %endif

    %ifdef REPORT_ERROR
error_msg:
    db "An error occurred during the reading of the image.", 0xd, 0xa, 0
    %endif

    times 510-($-$$) db 0
    db 0x55, 0xaa
