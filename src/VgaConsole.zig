const std = @import("std");
const io = std.io;

const vga = @import("./vga.zig");

x: usize = 0,
y: usize = 0,

const Self = @This();

pub fn obtain() Self {
    var console = Self{};
    console.clear();
    return console;
}

pub fn clear(self: *Self) void {
    vga.clear();
    self.x, self.y = .{ 0, 0 };
}

pub fn scroll(self: *Self) void {
    vga.scroll();
    self.y = if (self.y != 0) self.y - 1 else 0;
}

pub fn write(self: *Self, bytes: []const u8) error{}!usize {
    self.x, self.y = vga.printStr(bytes, self.x, self.y);
    return bytes.len;
}

const Writer = io.Writer(
    *Self,
    error{},
    write,
);

pub fn writer(self: *Self) Writer {
    return .{ .context = self };
}
