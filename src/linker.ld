SECTIONS {
    .boot 0x7c00 : AT(KERNEL_BEGIN) {
        KEEP(*(.boot))
    }

    . = 0xffffffff80000000; /* higher 2GB */
    KERNEL_OFFSET = .;
    . += 0x20000; /* boot stack offset */
    KERNEL_BEGIN = .;
    .gdt ALIGN(. + SIZEOF(.boot), 16) : AT(.) {
        KEEP(*(.gdt))
        KEEP(*(.gdt.tss))
        GDT_SIZE = SIZEOF(.gdt);
    }
    .rt : {
        *(.rt)
        *(.rt.*)
    }
    .vbr_header (KERNEL_BEGIN + 0x1fe) : AT(.) {
        SHORT(0xaa55)
    }

    .text : {
        *(.text)
        *(.text.*)
    }
    .rodata : ALIGN(4K) {
        *(.rodata)
        *(.rodata.*)
    }
    .data : ALIGN(4K) {
        *(.data)
        *(.data.*)
    }
    .bss : ALIGN(4K) {
        BSS_BEGIN = .;
        *(COMMON)
        *(.bss)
        *(.bss.*)
        BSS_SIZE = . - BSS_BEGIN;
    }
    . = ALIGN(4K);
    VGA_BUF = .;
    . += 4K;
    ASSERT((. - KERNEL_BEGIN) <= 128K, "Error: size of kernel exceeded 128KiB limit")

    STACK_PAGES = 0x20000 / 4K;
    TEXT_PAGES = ALIGN(SIZEOF(.text) + 0x200, 4K) / 4K;
    RODATA_PAGES = ALIGN(SIZEOF(.rodata), 4K) / 4K;
    DATA_PAGES = ALIGN(SIZEOF(.data), 4K) / 4K;
    BSS_PAGES = ALIGN(SIZEOF(.bss), 4K) / 4K;
}
