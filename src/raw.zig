pub fn inb(port: u16) u8 {
    return asm volatile (
        \\ in %dx, %al
        : [value] "{al}" (-> u8),
        : [port] "{dx}" (port),
    );
}

pub fn inw(port: u16) u8 {
    return asm volatile (
        \\ in %dx, %al
        : [value] "{ax}" (-> u16),
        : [port] "{dx}" (port),
    );
}

pub fn ind(port: u32) u8 {
    return asm volatile (
        \\ in %dx, %eax
        : [value] "{eax}" (-> u32),
        : [port] "{dx}" (port),
    );
}

pub fn outb(port: u16, value: u8) void {
    asm volatile (
        \\ out %al, %dx
        :
        : [port] "{dx}" (port),
          [value] "{al}" (value),
    );
}

pub fn outw(port: u16, value: u16) void {
    asm volatile (
        \\ out %ax, %dx
        :
        : [port] "{dx}" (port),
          [value] "{ax}" (value),
    );
}

pub fn outd(port: u16, value: u32) void {
    asm volatile (
        \\ out %eax, %dx
        :
        : [port] "{dx}" (port),
          [value] "{eax}" (value),
    );
}
