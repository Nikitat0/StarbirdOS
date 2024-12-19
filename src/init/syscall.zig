const x86_64 = @import("root").x86_64;
const msr = x86_64.msr;

const gdt = @import("gdt.zig");

pub fn init() void {
    var efer = msr.read(msr.Efer);
    efer.sce = true;
    msr.write(efer);
    msr.write(msr.Star{
        .syscall_cs = gdt.kernel_code,
        .sysret_cs = (gdt.user_code -% 16) | 3,
    });
    msr.write(msr.Sfmask{
        .flag_mask = 0x600,
    });
}
