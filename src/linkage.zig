pub fn symbol(comptime T: type, comptime name: []const u8) T {
    return @extern(T, .{ .name = name });
}

pub fn value(comptime symbol_name: []const u8) usize {
    const value_symbol = comptime symbol(*const anyopaque, symbol_name);
    return @intFromPtr(value_symbol);
}

pub fn loadAddr(virtual_addr: anytype) usize {
    return @intFromPtr(virtual_addr) - value("KERNEL_OFFSET");
}
