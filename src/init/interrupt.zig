const std = @import("std");
const alloc = @import("../alloc.zig");
const interrupts = @import("../interrupt.zig");
const allocator = alloc.allocator;
const GateDescriptor = interrupts.GateDescriptor;

const handler = fn (*const Context) callconv(.SysV) void;

pub var handlers: [256]?*const handler = .{null} ** 256;

var trampolines: [256]ISR align(8 * 256) = undefined;
var idt: interrupts.IDT = undefined;

pub fn init() callconv(.C) void {
    for (&trampolines, &idt) |*trampoline, *gate_descriptor| {
        trampoline.init();
        gate_descriptor.* = GateDescriptor.init(@ptrCast(trampoline), .Interrupt);
    }
    interrupts.loadIdt(&idt);
}

const ISR = packed struct(u56) {
    @"push imm8": u8 = 0x6a,
    vector: u8,
    @"jmp rel32": u8 = 0xe9,
    offset: u32,

    const Self = @This();

    pub fn init(self: *Self) void {
        const from = @intFromPtr(self) + @divExact(@bitSizeOf(Self), 8);
        const to = @intFromPtr(&interruptHandler);
        self.* = .{
            .vector = @truncate(@intFromPtr(self) / 8),
            .offset = @truncate(to -% from),
        };
    }
};

pub fn defaultHandler(ctx: *const Context) callconv(.SysV) void {
    std.debug.panic(
        \\unhandled interrupt {}
        \\context: {}
    , .{ ctx.vector, ctx });
}

pub const Context = extern struct {
    rax: u64,
    rcx: u64,
    rdx: u64,
    rbx: u64,
    rbp: u64,
    rsi: u64,
    rdi: u64,
    r: [8]u64,
    vector: u8,
    error_code: u64,
    rip: u64,
    cs: u16,
    rflags: u64,
    rsp: u64,
    ss: u16,
};

pub fn interruptHandler() callconv(.Naked) void {
    asm volatile (
        \\testb $0xf, %%spl
        \\jnz 1f
        \\push (%%rsp)
        \\1:
        \\
        \\push %%r15
        \\push %%r14
        \\push %%r13
        \\push %%r12
        \\push %%r11
        \\push %%r10
        \\push %%r9
        \\push %%r8
        \\push %%rdi
        \\push %%rsi
        \\push %%rbp
        \\push %%rbx
        \\push %%rdx
        \\push %%rcx
        \\push %%rax
        \\mov %%rsp, %%rdi
        \\
        \\movzbl 0x78(%%rsp), %%eax
        \\mov %[handlers:P](, %%rax, 0x8), %%rax
        \\test %%rax, %%rax
        \\jnz 1f
        \\lea %[defaultHandler:P], %%rax
        \\1:
        \\call *%%rax
        \\
        \\pop %%rax
        \\pop %%rcx
        \\pop %%rdx
        \\pop %%rbx
        \\pop %%rbp
        \\pop %%rsi
        \\pop %%rdi
        \\pop %%r8
        \\pop %%r9
        \\pop %%r10
        \\pop %%r11
        \\pop %%r12
        \\pop %%r13
        \\pop %%r14
        \\pop %%r15
        \\add $16, %%rsp
        \\iretq
        :
        : [defaultHandler] "s" (&defaultHandler),
          [handlers] "s" (&handlers),
    );
}
