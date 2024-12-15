const x86_64 = @import("root").x86_64;
const SegmentDescriptor = x86_64.SegmentDescriptor;

export const GDT linksection(".gdt") = [_]SegmentDescriptor{
    SegmentDescriptor.null,
    .{
        .executable = true,
        .dpl = .supervisor,
        .size = .@"64",
    },
    .{
        .executable = false,
        .dpl = .supervisor,
        .size = .@"32",
    },
};

pub const kernel_code: u16 = 8;
pub const kernel_data: u16 = 16;
