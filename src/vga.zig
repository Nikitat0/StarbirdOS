const std = @import("std");
const Tuple = std.meta.Tuple;

const linkage = @import("root").linkage;
const x86_64 = @import("root").x86_64;
const io_ports = x86_64.io_ports;

const width: usize = 80;
const height: usize = 25;
const size: usize = width * height;

const text_buffer: []volatile u16 = linkage.symbol([*]volatile u16, "VGA_BUF")[0..size];

pub fn clear() void {
    @memset(text_buffer, 0);
}

pub fn scroll() void {
    for (text_buffer[0 .. size - width], text_buffer[0 + width ..]) |*dst, src| {
        dst.* = src;
    }
    @memset(text_buffer[size - width ..], 0);
}

pub fn printChar(char: u8, x: usize, y: usize) void {
    text_buffer[x + y * width] = @as(u16, 0xf00) + char;
}

pub fn printStr(str: []const u8, start_x: usize, start_y: usize) Tuple(&.{ usize, usize }) {
    var x = start_x;
    var y = start_y;
    for (str) |c| {
        if (y == height) {
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
        if (x >= width) {
            x = 0;
            y += 1;
        }
    }
    return .{ x, y };
}

pub fn disableCursor() void {
    io_ports.outb(0x3d4, 0x0a);
    io_ports.delay();
    io_ports.outb(0x3d5, 0x20);
}
