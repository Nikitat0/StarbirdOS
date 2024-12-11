pub const PrivelegeLevel = enum(u2) {
    supervisor = 0,
    ring1,
    ring2,
    user,
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
    reservedFlag: bool = undefined,
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

    const @"null": SegmentDescriptor = @bitCast(@as(u64, 0));
};

export const gdt linksection(".gdt") = [_]SegmentDescriptor{
    SegmentDescriptor.null,
    SegmentDescriptor{
        .executable = true,
        .dpl = .supervisor,
        .size = .@"64",
    },
    SegmentDescriptor{
        .executable = false,
        .dpl = .supervisor,
        .size = .@"32",
    },
};
