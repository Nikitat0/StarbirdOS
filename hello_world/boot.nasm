    bits 16

    cli
    mov sp, 0x7c2
    mov ss, sp

    mov bx, len
    mov ah, 0xe
loop:
    mov al, ss:[bx]
    int 0x10
    dec bx
    jne loop

sleep:
    jmp sleep

    times 0x21-($-$$) db 0

msg:
    db "!dlrow , olleH"
    len equ $ - msg

    times 510-($-$$) db 0
    db 0x55, 0xaa
