export fn _start() noreturn {
    kernel_main();
}

export fn kernel_main() noreturn {
    const addr: *u16 = @ptrFromInt(0xb8000);
    addr.* = 0;
    while (true) {}
}
