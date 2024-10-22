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
    const addr: *u16 = @ptrFromInt(0xb8000);
    addr.* = 0;
    vga.disableCursor();
    var console = VgaConsole.obtain();
    console.writer().print("{s}", .{LOGO}) catch {};
    while (true) {}
}
