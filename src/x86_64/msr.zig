pub fn read(comptime Msr: type) Msr {
    var lo: u32 = undefined;
    var hi: u32 = undefined;
    asm (
        \\rdmsr
        : [eax] "={eax}" (lo),
          [edx] "={edx}" (hi),
        : [msr] "{ecx}" (Msr.address),
    );
    return @bitCast([_]u32{ lo, hi });
}

pub fn write(msr: anytype) void {
    const value: [2]u32 = @bitCast(msr);
    asm volatile (
        \\wrmsr
        :
        : [eax] "{eax}" (value[0]),
          [edx] "{edx}" (value[1]),
          [msr] "{ecx}" (@TypeOf(msr).address),
    );
}

pub const Efer = packed struct(u64) {
    sce: bool,
    padding1: u7 = 0,
    lme: bool,
    padding2: u1 = 0,
    lma: bool,
    nxe: bool,
    padding3: u52 = 0,

    const address = 0xc0000080;
};

pub const Star = packed struct(u64) {
    padding: u32 = 0,
    syscall_cs: u16,
    sysret_cs: u16,

    const address = 0xc0000081;
};

pub const Lstar = packed struct(u64) {
    syscall_target: usize,

    const address = 0xc0000082;
};

pub const Sfmask = packed struct(u64) {
    flag_mask: u32,
    _raz: u32 = undefined,

    const address = 0xc0000084;
};
