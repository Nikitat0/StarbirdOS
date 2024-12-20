    RETRY_COUNT equ 5

    bits 16

    cli
    xor sp, sp
    mov bp, 0x1000
    mov ss, bp
    sti
    shl bp, 1
    mov ds, bp

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
    jmp on_read_error
    %else
    jmp $
    %endif
.success:
    add cl, al ; add cl, 2
    cmp cl, 19
    jne .no_carry
    mov cl, 1
    add ch, dh
    xor dh, 1
.no_carry:
    mov ah, 2
    add bp, 0x40
    mov es, bp
    cmp bp, 0x8000
    jne read_loop

    cli
    lgdt [dgdt]
    mov eax, cr0
    or al, 1
    mov cr0, eax
    mov bx, DATA_SEG
    mov ds, bx
    mov ss, bx
    mov es, bx
    mov esp, 0x20000
    jmp CODE_SEG:(protected_mode_entry + 0x7c00)

    bits 32
protected_mode_entry:
    mov fs, bx
    mov gs, bx
    jmp 0x20200 - 0x7c00
    bits 16

gdt:
    dq 0
gdt_code:
    dw 0xffff, 0, 0x9a00, 0xcf
gdt_data:
    dw 0xffff, 0, 0x9200, 0xcf
gdt_end:

    CODE_SEG equ gdt_code - gdt
    DATA_SEG equ gdt_data - gdt

dgdt:
    dw gdt_end - gdt - 1
    dd gdt + 0x20000

    %ifdef REPORT_ERROR
on_read_error:
    cld
    mov ax, 0x7c0
    mov ds, ax
    lea si, [error_msg]
    mov ah, 0xe
.loop:
    lodsb
    test al, al
.halt:
    jz .halt
    int 0x10
    jmp .loop

error_msg:
    db 0xd, 0xa, "An error occurred during reading of the image", 0
    %endif

    %ifdef CODE_SIZE
    %assign CODE_SIZE $ - $$
    %warning Code size is CODE_SIZE
    %endif

    times 510-($-$$) db 0
    db 0x55, 0xaa
