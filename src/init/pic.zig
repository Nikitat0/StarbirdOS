const pic = @import("../pic.zig");

pub fn init() void {
    pic.master_pic.init(.{ .chip = .master, .vectorOffset = 0x20 });
    pic.slave_pic.init(.{ .chip = .slave, .vectorOffset = 0x28 });
}
