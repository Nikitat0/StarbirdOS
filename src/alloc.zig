const std = @import("std");

var buffer: [1024 * 1024]u8 = undefined;
var _allocator = std.heap.FixedBufferAllocator.init(&buffer);

pub const allocator = _allocator.allocator();
