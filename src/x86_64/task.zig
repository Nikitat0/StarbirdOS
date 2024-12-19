pub const StateSegment = extern struct {
    reserved1: u32 = 0,
    rsps: [3][2]u32 = .{.{ 0, 0 }} ** 3,
    reserved2: [2]u32 = .{ 0, 0 },
    ists: [7][2]u32 = .{.{ 0, 0 }} ** 7,
    reserved3: [5]u16 = .{0} ** 5,
    iopb: u16 = @sizeOf(Self),

    const Self = @This();

    pub fn rsp(self: *Self, n: comptime_int) *align(@alignOf(u32)) usize {
        return @ptrCast(&self.rsps[n]);
    }

    pub fn ist(self: *Self, n: comptime_int) *align(@alignOf(u32)) usize {
        return @ptrCast(&self.ists[n]);
    }
};

pub fn load(gdt_offset: u16) void {
    asm volatile (
        \\ltr %[tr:w]
        :
        : [tr] "r" (gdt_offset),
    );
}
