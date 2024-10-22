SECTIONS {
    . = 0xffffffff80020200;
    .text : {
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
