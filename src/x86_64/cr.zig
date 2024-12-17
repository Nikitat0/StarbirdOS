const std = @import("std");
const fmt = std.fmt;

pub fn read(comptime T: type) T {
    return asm (fmt.comptimePrint(
            \\mov %%cr{}, %[cr:q]
        , .{T.number})
        : [cr] "=r" (-> T),
    );
}

pub fn write(value: anytype) void {
    asm volatile (fmt.comptimePrint(
            \\mov %[cr:q], %%cr{}
        , .{@TypeOf(value).number})
        :
        : [cr] "r" (value),
    );
}

pub const @"0" = packed struct(u32) {
    pe: bool,
    mp: bool,
    em: bool,
    padding1: u13 = 0,
    wp: bool,
    padding2: u14 = 0,
    pg: bool,

    const number = 0;
};
