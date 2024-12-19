const std = @import("std");
const io = std.io;

const interrupts = @import("root").interrupts;
const jedi = @import("root").jedi;
const linkage = @import("root").linkage;
const vga = @import("root").vga;

const x86_64 = @import("root").x86_64;
const msr = x86_64.msr;
const paging = x86_64.paging;
const pic = x86_64.pic;
const task = x86_64.task;

pub fn main() void {
    pic.Device.keyboard.enable();
    interrupts.setHandler(0x21, &keyboardHandler);
    asm volatile (
        \\sti
    );

    vga.disableCursor();
    var console = vga.Console.obtain();
    console.writer().print("{s}", .{@embedFile("logo")}) catch {};

    while (!@as(*volatile bool, &doContinue).*) {}
    console.clear();

    const kernel_pml4 = asm volatile (
        \\mov %%cr3, %[r]
        \\addq $0xffffffff80000000, %[r]
        : [r] "=r" (-> *const paging.Table),
    );
    var kstack_entry = paging.TableEntry.init(0x60000);
    kstack_entry.flags.writable = true;
    kstack_entry.flags.nonExecutable = true;
    var stack_entry = paging.TableEntry.init(0x60000);
    stack_entry.flags.user = true;
    stack_entry.flags.writable = true;
    stack_entry.flags.nonExecutable = true;
    for (&proc_pagings) |*proc_paging| {
        proc_paging.pml4 = kernel_pml4.*;
        proc_paging.pml4[0] = paging.TableEntry.init(linkage.loadAddr(&proc_paging.pdp));
        proc_paging.pml4[0].flags.user = true;
        proc_paging.pml4[0].flags.writable = true;
        proc_paging.pdp[0] = paging.TableEntry.init(linkage.loadAddr(&proc_paging.pd));
        proc_paging.pdp[0].flags.user = true;
        proc_paging.pdp[0].flags.writable = true;
        proc_paging.pd[0] = paging.TableEntry.init(linkage.loadAddr(&proc_paging.pt));
        proc_paging.pd[0].flags.user = true;
        proc_paging.pd[0].flags.writable = true;

        var i: usize = 256 - 32;
        for (0..16) |_| {
            proc_paging.pt[i] = kstack_entry;
            kstack_entry.raw += 0x1000;
            i += 1;
        }
        for (0..16) |_| {
            proc_paging.pt[i] = stack_entry;
            stack_entry.raw += 0x1000;
            i += 1;
        }

        var entry = paging.TableEntry.init(0x40000);
        entry.flags.user = true;
        proc_paging.pt[i] = entry;

        paging.setTopLevelTable(linkage.loadAddr(&proc_pagings[0].pml4));
        const header: *const jedi.Header = @ptrFromInt(0x100000);

        for (0..header.text_pages - 1) |_| {
            i += 1;
            entry.raw += 0x1000;
            proc_paging.pt[i] = entry;
        }

        entry.flags.nonExecutable = true;
        for (0..header.rodata_pages) |_| {
            i += 1;
            entry.raw += 0x1000;
            proc_paging.pt[i] = entry;
        }

        entry.flags.writable = true;
        for (0..header.data_pages + header.bss_pages) |_| {
            i += 1;
            entry.raw += 0x1000;
            proc_paging.pt[i] = entry;
        }

        const bss_begin: [*]u8 = @ptrFromInt(0x100000 + header.bssPageOffset());
        const bss_size: usize = header.bss_pages * 4096;
        @memset(bss_begin[0..bss_size], 0);
    }
    tss.rsp(0).* = 0x100000 - 16 * 4096;

    interrupts.setHandler(0x20, &timerHandler);
    msr.write(msr.Lstar{
        .syscall_target = @intFromPtr(&syscallTarget),
    });
    pic.Device.timer.enable();
}

var doContinue: bool = false;

pub fn keyboardHandler(_: *interrupts.Context) callconv(.SysV) void {
    doContinue = true;
    pic.Device.keyboard.sendEoi();
}

pub var tss: task.StateSegment = .{};

var proc_pagings: [4]extern struct {
    pml4: paging.Table = paging.empty_table,
    pdp: paging.Table = paging.empty_table,
    pd: paging.Table = paging.empty_table,
    pt: paging.Table = paging.empty_table,
} align(4096) = .{.{}} ** 4;

var proc_ctxs: [4]?*const interrupts.Context = .{null} ** 4;

var current_proc: ?u2 = null;

pub fn timerHandler(ctx: *interrupts.Context) callconv(.SysV) void {
    if (current_proc) |n| {
        proc_ctxs[n] = ctx;
    } else {
        current_proc = 3;
    }
    current_proc.? +%= 1;
    pic.Device.timer.sendEoi();
    enterTask(current_proc.?);
}

pub fn enterTask(n: u2) void {
    paging.setTopLevelTable(linkage.loadAddr(&proc_pagings[n].pml4));

    if (proc_ctxs[n] == null) {
        asm volatile ("sysretq"
            :
            : [arg] "{rdi}" (@as(usize, n)),
              [rip] "{rcx}" (0x100000 + @sizeOf(jedi.Header)),
              [rflags] "{r11}" (0x202),
              [rsp] "{rsp}" (0x100000 - 8),
        );
    }
    asm volatile (
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
        : [ctx] "{rsp}" (proc_ctxs[n]),
    );
}

pub fn syscallTarget() callconv(.Naked) void {
    asm volatile (
        \\push %%r11
        \\push %%r10
        \\push %%r9
        \\push %%r8
        \\push %%rdi
        \\push %%rsi
        \\push %%rcx
        \\push %%rax
        \\mov %%rsp, %%rax
        \\andq $-16, %%rsp
        \\pushq $0
        \\push %%rax
        \\
        \\
        \\call %[handler:P]
        \\
        \\pop %%rsp
        \\pop %%rax
        \\pop %%rcx
        \\pop %%rsi
        \\pop %%rdi
        \\pop %%r8
        \\pop %%r9
        \\pop %%r10
        \\pop %%r11
        \\sysretq
        :
        : [handler] "s" (&syscallHandler),
    );
}

pub fn syscallHandler(ptr: [*]const u8, len: usize) callconv(.SysV) void {
    consoles[current_proc.?].writer().print("{s} ", .{ptr[0..len]}) catch {};
}

var consoles = [4]QuadConsole{
    .{ .base_x = 0, .base_y = 0 },
    .{ .base_x = 41, .base_y = 0 },
    .{ .base_x = 0, .base_y = 13 },
    .{ .base_x = 41, .base_y = 13 },
};

pub const QuadConsole = struct {
    base_x: usize,
    base_y: usize,
    x: usize = 0,
    y: usize = 0,

    const Self = @This();

    const num_columns = 39;
    const num_rows = 12;

    pub fn scroll(self: Self) void {
        for (0..num_rows - 1) |y| {
            for (0..num_columns) |x| {
                vga.text_buffer[self.base_x + x + (self.base_y + y) * 80] =
                    vga.text_buffer[self.base_x + x + (self.base_y + y + 1) * 80];
            }
        }
    }

    pub fn printStr(self: *Self, str: []const u8) void {
        for (str) |c| {
            if (self.y == num_rows) {
                self.scroll();
                self.y -= 1;
            }
            if (c == '\n') {
                self.x = 0;
                self.y += 1;
                continue;
            }
            vga.printChar(c, self.base_x + self.x, self.base_y + self.y);
            self.x += 1;
            if (self.x == num_columns) {
                self.x = 0;
                self.y += 1;
            }
        }
    }

    pub fn write(self: *Self, bytes: []const u8) error{}!usize {
        self.printStr(bytes);
        return bytes.len;
    }

    const Writer = io.Writer(
        *Self,
        error{},
        write,
    );

    pub fn writer(self: *Self) Writer {
        return .{ .context = self };
    }
};
