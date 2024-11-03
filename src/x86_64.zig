pub const PrivelegeLevel = enum(u2) {
    Supervisor = 0,
    Ring1,
    Ring2,
    User,
};

pub const SegmentSelector = enum(u16) {
    KernelCode = 8,
    KernelData = 16,
};
