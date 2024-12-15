const std = @import("std");

const x86_64 = @import("root").x86_64;
const interrupts = x86_64.interrupts;
const GateDescriptor = interrupts.GateDescriptor;

const gdt = @import("gdt.zig");

pub var handlers: [256]?*const Handler = .{null} ** 256;

pub const Handler = fn (*Context) callconv(.SysV) void;

pub const Context = extern struct {
    rax: u64,
    rcx: u64,
    rdx: u64,
    rbx: u64,
    rbp: u64,
    rsi: u64,
    rdi: u64,
    r8: u64,
    r9: u64,
    r10: u64,
    r11: u64,
    r12: u64,
    r13: u64,
    r14: u64,
    r15: u64,
    vector: u8,
    error_code: u64,
    rip: u64,
    cs: u16,
    rflags: u64,
    rsp: u64,
    ss: u16,
};

var idt: [256]GateDescriptor = undefined;
var isrs: [256]Isr align(256 * @sizeOf(Isr)) = undefined;

pub fn init() callconv(.C) void {
    for (&handlers) |*handler|
        handler.* = &defaultHandler;
    for (&isrs, &idt) |*trampoline, *gate_descriptor| {
        trampoline.init();
        gate_descriptor.* = GateDescriptor.init(.{
            .handler = @ptrCast(trampoline),
            .type = .interrupt,
            .cs = gdt.kernel_code,
        });
    }
    interrupts.lidt(&idt);
}

const Isr = packed struct {
    @"push imm8": u8 = 0x6a,
    vector: u8,
    cld: u8 = 0xfc,
    @"jmp rel32": u8 = 0xe9,
    offset: u32,

    const Self = @This();

    pub fn init(self: *Self) void {
        const from = @intFromPtr(self) + @divExact(@bitSizeOf(Self), 8);
        const to = @intFromPtr(&dispatch);
        self.* = .{
            .vector = @truncate(@intFromPtr(self) / @sizeOf(Self)),
            .offset = @truncate(to -% from),
        };
    }
};

pub fn defaultHandler(ctx: *Context) callconv(.SysV) void {
    std.debug.panic(
        \\unhandled interrupt {}
        \\context: {}
    , .{ ctx.vector, ctx });
}

pub fn dispatch() callconv(.Naked) void {
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
        : [handlers] "s" (&handlers),
    );
}
