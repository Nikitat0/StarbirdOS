pub const cr = @import("x86_64/cr.zig");
pub const interrupts = @import("x86_64/interrupts.zig");
pub const io_ports = @import("x86_64/io_ports.zig");
pub const msr = @import("x86_64/msr.zig");
pub const paging = @import("x86_64/paging.zig");
pub const pic = @import("x86_64/pic.zig");

pub const PrivelegeLevel = enum(u2) {
    supervisor = 0,
    ring1,
    ring2,
    user,
};

pub const DescriptorTableDescriptor = packed struct(u80) {
    size: u16,
    offset: u64,
};

pub const SegmentDescriptor = packed struct(u64) {
    limit1: u16 = 0xffff,
    base1: u24 = 0,
    accessed: bool = true,
    rw: bool = true,
    dc: bool = false,
    executable: bool,
    segment: bool = true,
    dpl: PrivelegeLevel,
    present: bool = true,
    limit2: u4 = 0xf,
    reserved_flag: bool = undefined,
    size: Size,
    granularity: Granularity = .pages,
    base2: u8 = 0,

    pub const Granularity = enum(u1) {
        bytes,
        pages,
    };

    pub const Size = enum(u2) {
        @"16" = 0b00,
        @"32" = 0b10,
        @"64" = 0b01,
    };

    pub const @"null": SegmentDescriptor = @bitCast(@as(u64, 0));
};
