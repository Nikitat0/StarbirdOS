pub const std = @import("std");
pub const x86_64 = @import("../x86_64.zig");

pub const Handler = fn () callconv(.Interrupt) void;

pub const GateDescriptor = packed struct(u128) {
    offset1: u16,
    cs: u16,
    ist: u3,
    padding1: u5 = 0,
    type: Type,
    padding2: u1 = 0,
    dpl: x86_64.PrivelegeLevel,
    present: bool,
    offset2: u48,
    padding3: u32 = 0,

    pub fn init(opts: Options) GateDescriptor {
        const offset = @intFromPtr(opts.handler);
        return .{
            .offset1 = @truncate(offset),
            .offset2 = @truncate(offset >> 16),
            .cs = opts.cs,
            .ist = opts.ist,
            .type = opts.type,
            .dpl = opts.dpl,
            .present = true,
        };
    }

    pub const Options = struct {
        handler: *const Handler,
        cs: u16,
        ist: u3 = 0,
        type: Type,
        dpl: x86_64.PrivelegeLevel = .supervisor,
    };

    pub const Type = enum(u4) {
        interrupt = 0xE,
        trap = 0xF,
    };
};

pub const Idt = []GateDescriptor;

pub fn lidt(idt: Idt) void {
    const idtr = x86_64.DescriptorTableDescriptor{
        .size = @intCast(idt.len * @sizeOf(GateDescriptor) - 1),
        .offset = @intFromPtr(idt.ptr),
    };
    asm volatile (
        \\lidt (%[idtr])
        :
        : [idtr] "r" (&idtr),
    );
}
