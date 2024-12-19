const std = @import("std");
const builtin = std.builtin;

pub const linkage = @import("linkage.zig");
pub const x86_64 = @import("x86_64.zig");

pub const jedi = @import("jedi.zig");
pub const vga = @import("./vga.zig");

pub const interrupts = @import("interrupts.zig");

export fn startup() noreturn {
    @import("init.zig").init();
    @import("main.zig").main();
    while (true) {}
}

pub fn panic(msg: []const u8, _: ?*builtin.StackTrace, _: ?usize) noreturn {
    var console = vga.Console.obtain();
    const writer = console.writer();
    writer.print("kernel panic: {s}\n", .{msg}) catch {};
    while (true) {}
}
