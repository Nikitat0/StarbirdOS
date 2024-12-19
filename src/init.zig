pub fn init() void {
    @import("./init/gdt.zig").init();
    @import("./init/paging.zig").init();
    @import("./init/pic.zig").init();
    @import("./init/interrupt.zig").init();
    @import("./init/syscall.zig").init();
}
