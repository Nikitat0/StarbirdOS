const std = @import("std");
const fmt = std.fmt;

pub fn delay() void {
    outb(0x80, undefined);
}

pub fn inb(port: anytype) u8 {
    return in(u8, port);
}

pub fn inw(port: anytype) u16 {
    return in(u16, port);
}

pub fn ind(port: anytype) u32 {
    return in(u32, port);
}

fn in(comptime T: type, port: anytype) T {
    if (handlePort(port)) |coerced_port|
        return in(T, coerced_port);

    const format_args = switch (T) {
        u8 => .{ "b", "b" },
        u16 => .{ "w", "w" },
        u32 => .{ "l", "k" },
        else => unreachable,
    };
    return asm volatile (fmt.comptimePrint(
            \\in{s} %[port:w], %[value:{s}]
        , format_args)
        : [value] "={eax}" (-> T),
        : [port] "N{dx}" (port),
    );
}

pub fn outb(port: anytype, value: u8) void {
    out(port, value);
}

pub fn outw(port: anytype, value: u16) void {
    out(port, value);
}

pub fn outd(port: anytype, value: u32) void {
    out(port, value);
}

fn out(port: anytype, value: anytype) void {
    if (handlePort(port)) |coerced_port| {
        out(coerced_port, value);
        return;
    }

    const format_args = switch (@TypeOf(value)) {
        u8 => .{ "b", "b" },
        u16 => .{ "w", "w" },
        u32 => .{ "l", "k" },
        else => unreachable,
    };
    asm volatile (fmt.comptimePrint(
            \\out{s} %[value:{s}], %[port:w]
        , format_args)
        :
        : [port] "N{dx}" (port),
          [value] "{eax}" (value),
    );
}

/// Validates the io-port number.
/// Returns non-null value when comptime_int should be coerced to u16 for more optimal codegen.
fn handlePort(port: anytype) ?u16 {
    switch (@TypeOf(port)) {
        u8, u16 => {},
        comptime_int => switch (port) {
            0...0xff => {},
            0x100...0xffff => return @as(u16, port),
            else => @compileError("port must be in range [0, 2^16)"),
        },
        else => @compileError("type of port must be one of u8, u16 or comptime_int"),
    }
    return null;
}
