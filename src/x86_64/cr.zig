const std = @import("std");
const fmt = std.fmt;

pub fn read(comptime number: u4) u64 {
    return asm volatile (fmt.comptimePrint(
            \\mov %%cr{}, %[cr]
        , .{number})
        : [cr] "=r" (-> u64),
    );
}

pub fn write(comptime number: u4, value: u64) void {
    asm volatile (fmt.comptimePrint(
            \\mov %[cr], %%cr{}
        , .{number})
        :
        : [cr] "r" (value),
    );
}
