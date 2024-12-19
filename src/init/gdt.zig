const linkage = @import("root").linkage;

const x86_64 = @import("root").x86_64;
const SegmentDescriptor = x86_64.SegmentDescriptor;
const task = x86_64.task;

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
    .{
        .executable = false,
        .dpl = .user,
        .size = .@"32",
    },
    .{
        .executable = true,
        .dpl = .user,
        .size = .@"64",
    },
    SegmentDescriptor.null,
    SegmentDescriptor.null,
};

const tss_descriptor: *align(@alignOf(SegmentDescriptor)) volatile SegmentDescriptor.System = _: {
    break :_ @ptrCast(@constCast(&GDT[GDT.len - 2]));
};

pub fn init() void {
    tss_descriptor.* = SegmentDescriptor.System.init(
        @intFromPtr(&@import("../main.zig").tss),
        @sizeOf(task.StateSegment),
    );
    task.load((GDT.len - 2) * 8);
}

pub const kernel_code: u16 = 8;
pub const kernel_data: u16 = 16;
pub const user_data: u16 = 24;
pub const user_code: u16 = 32;
