pub const efer: u32 = 0xc0000080;

pub fn modify(msr: u32, comptime inline_asm: []const u8) void {
    asm volatile ("" ++
            \\ rdmsr
            \\
        ++ inline_asm ++
            \\
            \\ wrmsr
        :
        : [msr] "{ecx}" (msr),
        : "{eax}", "{edx}"
    );
}
