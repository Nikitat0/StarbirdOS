const std = @import("std");
const Tuple = std.meta.Tuple;

const utils = @import("./utils.zig");

const WIDTH: usize = 80;
const HEIGHT: usize = 25;
const SIZE: usize = WIDTH * HEIGHT;

const TEXT_BUFFER: []volatile u16 = @as([*]volatile u16, @ptrFromInt(0xb8000))[0..SIZE];

inline fn addressByCoords(x: usize, y: usize) usize {
    return x + y * WIDTH;
}

pub fn clear() void {
    @memset(TEXT_BUFFER, 0);
}

pub fn scroll() void {
    for (TEXT_BUFFER[0 .. SIZE - WIDTH], TEXT_BUFFER[0 + WIDTH ..]) |*dst, src| {
        dst.* = src;
    }
    @memset(TEXT_BUFFER[SIZE - WIDTH ..], 0);
}

pub fn printChar(char: u8, x: usize, y: usize) void {
    TEXT_BUFFER[addressByCoords(x, y)] = @as(u16, 0xf00) + char;
}

pub fn printStr(str: []const u8, start_x: usize, start_y: usize) Tuple(&.{ usize, usize }) {
    var x = start_x;
    var y = start_y;
    for (str) |c| {
        if (y == HEIGHT) {
            scroll();
            y -= 1;
        }
        if (c == '\n') {
            x = 0;
            y += 1;
            continue;
        }
        printChar(c, x, y);
        x += 1;
        if (x >= WIDTH) {
            x = 0;
            y += 1;
        }
    }
    return .{ x, y };
}

pub fn disableCursor() void {
    utils.outb(0x3d4, 0x0a);
    utils.outb(0x3d5, 0x20);
}
