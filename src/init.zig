pub fn init() void {
    @import("./init/pic.zig").init();
    @import("./init/interrupt.zig").init();
}
