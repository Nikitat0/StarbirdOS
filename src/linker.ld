SECTIONS {
    . = 0x20200;
    .text : AT(0x20200) {
        *(.text)
        *(.text.*)
    }
    .rodata : {
        *(.rodata)
        *(.rodata.*)
    }
    .data : {
        *(.data)
        *(.data.*)
    }
    .bss : {
        *(COMMON)
        *(.bss)
        *(.bss.*)
    }
}
