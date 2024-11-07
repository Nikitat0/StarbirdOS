    bits 16

    %assign i 0
    %rep 0x100
    %ifdef bytes
    %xdefine bytes bytes, i
    %else
    %xdefine bytes i
    %endif
    %assign i i + 1
    %endrep

    times 6 * 64 * 4 db bytes
