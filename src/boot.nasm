    bits 16

    cld

    cli
    mov sp, 0xffff
    mov bp, 0x1000
    mov ss, bp
    sti
    shl bp, 1
    mov ds, bp

    mov es, bp
    mov ax, 0x0202
    xor bx, bx
    xor cx, cx
    inc cx
    xor dh, dh
read_loop:
    int 0x13
    jc on_read_error
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

    cli

; Prepare first 2MiB identity paging
    mov di, 0x1d00
    mov es, di
    mov cx, 0x1800
    xor ax, ax
    xor di, di
    rep stosw
    mov byte ss:[0xf000], 0b10000001
    mov byte ss:[0xe000], 1
    mov word ss:[0xe001], 0x1f0
    mov byte ss:[0xd000], 1
    mov word ss:[0xd001], 0x1e0
    mov esp, 0x1d000

; Enable PAE
    mov edx, cr4
    or dl, 1 << 5
    mov cr4, edx

; Set LME
    mov ecx, 0xc0000080
    rdmsr
    or ah, 1 ; or eax, 1 << 8
    wrmsr

; Setup PML4
    mov eax, esp
    mov cr3, eax

; Enter long mode by setting PE & PG
    mov eax, cr0
    or eax, (1 << 31) | 1
    mov cr0, eax

    lgdt [dgdt]
    mov eax, cr0
    or al, 1
    mov cr0, eax
    mov bx, DATA_SEG
    mov ds, bx
    mov ss, bx
    mov es, bx
    jmp CODE_SEG:(long_mode_bootstrap + 0x7c00)

    bits 64
long_mode_bootstrap:
    mov fs, bx
    mov gs, bx
    jmp 0x20200 - 0x7c00
    bits 16

gdt:
    dq 0
gdt_code:
    dw 0xffff, 0, 0x9a00, 0xaf
gdt_data:
    dw 0xffff, 0, 0x9200, 0xcf
gdt_end:

    CODE_SEG equ gdt_code - gdt
    DATA_SEG equ gdt_data - gdt

dgdt:
    dw gdt_end - gdt - 1
    dd gdt + 0x20000

on_read_error:
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

    times 510-($-$$) db 0
    db 0x55, 0xaa
