const x86_64 = @import("root").x86_64;
const pic = x86_64.pic;

pub fn init() void {
    pic.master.init(.{ .chip = .master, .vector_offset = 0x20 });
    pic.slave.init(.{ .chip = .slave, .vector_offset = 0x28 });
}
