pub fn delay() void {
    outb(0x80, undefined);
}

pub fn switchVirtualSpace(top_level_pmt_phys_addr: anytype) void {
    asm volatile (
        \\ mov %rdi, %cr3
        :
        : [pmt] "{rdi}" (top_level_pmt_phys_addr),
    );
}

pub fn inb(port: u16) u8 {
    return asm volatile (
        \\ in %dx, %al
        : [value] "={rax}" (-> u8),
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

pub fn linkerSymbol(comptime T: type, comptime name: []const u8) T {
    if (@typeInfo(T) == .Pointer)
        return @extern(T, .{ .name = name });
    if (T == usize)
        return @intFromPtr(@extern(*anyopaque, .{ .name = name }));
    @compileError("linker symbol cannot be represented as " ++ @typeName(T));
}
