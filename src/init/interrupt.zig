const std = @import("std");
const alloc = @import("../alloc.zig");
const interrupts = @import("../interrupt.zig");
const allocator = alloc.allocator;
const GateDescriptor = interrupts.GateDescriptor;

const ISR = fn () callconv(.Interrupt) void;

const handlers: [256]?*const ISR = init: {
    const value = .{null} ** 256;
    break :init value;
};

pub fn init() void {
    const idt = allocator.create(interrupts.IDT) catch unreachable;
    for (0.., idt) |vector, *gate_descriptor| {
        const handler: *const ISR = if (handlers[vector]) |value| value else init: {
            const trampoline = allocator.create(Trampoline) catch unreachable;
            trampoline.* = Trampoline.init(@intCast(vector));
            break :init @ptrCast(trampoline);
        };
        gate_descriptor.* = GateDescriptor.init(handler, .Interrupt);
    }
    interrupts.loadIdt(idt);
}

const Trampoline = packed struct {
    @"mov edi, ...": u8 = 0xbf,
    vector: u32,
    @"mov rax, ...": u24 = 0xc0c748,
    handler: u32,
    @"jmp rax": u16 = 0xe0ff,

    const Self = @This();

    pub fn init(vector: u8) Self {
        return .{
            .vector = @intCast(vector),
            .handler = @truncate(@intFromPtr(&defaultInterruptHandler)),
        };
    }
};

pub fn defaultInterruptHandler(vector: u8) callconv(.SysV) void {
    @setAlignStack(1);
    std.debug.panic("unhandled interrupt {}", .{vector});
}
