const words = [_][]const u8{
    "first",
    "second",
    "third",
    "fourth",
};

export fn main(n: u8) callconv(.SysV) noreturn {
    while (true) {
        asm volatile ("syscall"
            :
            : [ptr] "{rdi}" (words[n].ptr),
              [len] "{rsi}" (words[n].len),
            : "rcx", "r11"
        );
    }
}
