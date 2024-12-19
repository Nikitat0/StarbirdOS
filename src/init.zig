const interrupts = @import("root").interrupts;

pub fn init() void {
    @import("./init/gdt.zig").init();
    @import("./init/paging.zig").init();
    @import("./init/pic.zig").init();
    interrupts.init();
    @import("./init/syscall.zig").init();
}
