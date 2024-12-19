SECTIONS {
    .header 0x100000 : {
        LONG(0x6964656a)
        LONG(0x0)
        QUAD(ALIGN(SIZEOF(.text), 4K) / 4K)
        QUAD(ALIGN(SIZEOF(.rodata), 4K) / 4K)
        QUAD(ALIGN(SIZEOF(.data), 4K) / 4K)
        QUAD(ALIGN(SIZEOF(.bss), 4K) / 4K)
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
        *(COMMON)
        *(.bss)
        *(.bss.*)
    }
    ASSERT((. - ADDR(.header)) <= 128K, "Error: size exceeded 128KiB limit")
}
