const std = @import("std");
const builtin = std.builtin;

const vga = @import("./vga.zig");
const VgaConsole = @import("./VgaConsole.zig");

const logo: []const u8 = @embedFile("logo");

export fn kernel_main() noreturn {
    @import("init.zig").init();

    vga.disableCursor();
    var console = VgaConsole.obtain();
    console.writer().print("{s}", .{logo}) catch {};

    while (true) {}
}

pub fn panic(msg: []const u8, _: ?*builtin.StackTrace, _: ?usize) noreturn {
    var console = VgaConsole.obtain();
    const writer = console.writer();
    writer.print("kernel panic: {s}\n", .{msg}) catch {};
    while (true) {}
}

pub const linkage = @import("linkage.zig");
pub const x86_64 = @import("x86_64.zig");

pub const process = @import("process.zig");
