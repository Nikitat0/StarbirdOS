org 0x7c00
bits 16

cli
xor ax, ax
mov ss, ax
mov es, ax
mov sp, 0x7c00
sti

mov bp, msg
mov cx, len
mov ah, 0x13
mov bl, 1
int 0x10

hlt

msg: db "Hello, world!"
len equ $ - msg

times 510-($-$$) db 0
db 0x55, 0xaa
