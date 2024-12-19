const x86_64 = @import("root").x86_64;
const task = x86_64.task;

pub var tss: task.StateSegment = .{};
