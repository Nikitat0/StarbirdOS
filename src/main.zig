export fn _start() callconv(.Naked) noreturn {
    asm volatile (
        \\callq %[main:P]
        :
        : [main] "s" (&kernel_main),
    );
}

fn kernel_main() noreturn {
    const addr: *u16 = @ptrFromInt(0xb8000);
    addr.* = 0;
    while (true) {}
}
