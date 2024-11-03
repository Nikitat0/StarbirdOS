const std = @import("std");
const builtin = std.builtin;

const vga = @import("./vga.zig");
const VgaConsole = @import("./VgaConsole.zig");

export fn _start() callconv(.Naked) noreturn {
    asm volatile (
        \\callq %[main:P]
        :
        : [main] "s" (&kernel_main),
    );
}

const LOGO: []const u8 = @embedFile("./logo.txt");

fn kernel_main() noreturn {
    @import("init.zig").init();
    vga.disableCursor();
    var console = VgaConsole.obtain();
    console.writer().print("{s}", .{LOGO}) catch {};
    while (true) {}
}

pub fn panic(msg: []const u8, _: ?*builtin.StackTrace, _: ?usize) noreturn {
    var console = VgaConsole.obtain();
    const writer = console.writer();
    writer.print("kernel panic: {s}\n", .{msg}) catch {};
    while (true) {}
}
