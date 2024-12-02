pub const std = @import("std");
pub const x86_64 = @import("./x86_64.zig");

pub const IDT = [256]GateDescriptor;

pub const GateDescriptor = packed struct {
    offset1: u16,
    cs: x86_64.SegmentSelector = .KernelCode,
    ist: u3,
    padding1: u5 = 0,
    gate_type: GateType,
    padding2: u1 = 0,
    dpl: x86_64.PrivelegeLevel,
    present: u1,
    offset2: u48,
    padding3: u32 = 0,

    pub const InterruptHandler = fn () callconv(.Interrupt) void;

    pub fn init(handler: *const InterruptHandler, gate_type: GateType) GateDescriptor {
        const offset = @intFromPtr(handler);
        return .{
            .offset1 = @truncate(offset),
            .offset2 = @truncate(offset >> 16),
            .ist = 0,
            .gate_type = gate_type,
            .dpl = .Supervisor,
            .present = 1,
        };
    }
};

comptime {
    std.debug.assert(@bitSizeOf(GateDescriptor) == 128);
}

pub const GateType = enum(u4) {
    Interrupt = 0xE,
    Trap = 0xF,
};

pub fn loadIdt(idt: []GateDescriptor) void {
    const idtr = packed struct {
        size: u16,
        offset: [*]GateDescriptor,
    }{ .size = @intCast(idt.len * @sizeOf(GateDescriptor) - 1), .offset = idt.ptr };
    comptime std.debug.assert(@bitSizeOf(@TypeOf(idtr)) == 80);
    asm volatile (
        \\ lidt (%rax)
        :
        : [idtr] "{rax}" (&idtr),
    );
}
