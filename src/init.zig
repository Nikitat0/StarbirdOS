pub fn init() void {
    @import("./init/paging.zig").init();
    @import("./init/pic.zig").init();
    @import("./init/interrupt.zig").init();
}

comptime {
    _ = @import("init/gdt.zig");
}
