const std = @import("std");

var pml4: TranslationTable = .{TranslationEntry.empty} ** 512;
var pdp: TranslationTable = .{TranslationEntry.empty} ** 512;
var pd: TranslationTable = .{TranslationEntry.empty} ** 512;
var pt: TranslationTable = .{TranslationEntry.empty} ** 512;

const linkerSymbol = @import("../utils.zig").linkerSymbol;

pub fn init() void {
    @memset(linkerSymbol([*]u8, "BSS_BEGIN")[0..linkerSymbol(usize, "BSS_SIZE")], 0);

    // Set CR0.WP
    asm volatile (
        \\ mov %%cr0, %[r]
        \\ or $0x10000, %[r]
        \\ mov %[r], %%cr0
        :
        : [r] "r" (@as(usize, undefined)),
    );

    // Set EFER.NXE
    asm volatile (
        \\ rdmsr
        \\ or $0x800, %%eax
        \\ wrmsr
        :
        : [efer] "{ecx}" (0xc0000080),
        : "rax", "rdx"
    );

    const kernel_offset = linkerSymbol(usize, "KERNEL_OFFSET");

    var gdtr: packed struct {
        size: u16,
        offset: u64,
    } = undefined;

    asm volatile (
        \\sgdt (%[r])
        :
        : [r] "r" (&gdtr),
    );

    gdtr.offset += kernel_offset;

    asm volatile (
        \\lgdt (%[r])
        :
        : [r] "r" (&gdtr),
    );

    pml4[511] = TranslationEntry.init(@intFromPtr(&pdp) - kernel_offset);
    pml4[511].flags.writable = true;
    pdp[510] = TranslationEntry.init(@intFromPtr(&pd) - kernel_offset);
    pdp[510].flags.writable = true;
    pd[0] = TranslationEntry.init(@intFromPtr(&pt) - kernel_offset);
    pd[0].flags.writable = true;

    var i: usize = 0;
    var entry = TranslationEntry.init(0);

    entry.flags.writable = true;
    entry.flags.nonExecutable = true;
    for (0..linkerSymbol(usize, "STACK_PAGES")) |_| {
        pt[i] = entry;
        i += 1;
        entry.raw += 0x1000;
    }

    entry.flags.writable = false;
    entry.flags.nonExecutable = false;
    for (0..linkerSymbol(usize, "TEXT_PAGES")) |_| {
        pt[i] = entry;
        i += 1;
        entry.raw += 0x1000;
    }

    entry.flags.nonExecutable = true;
    for (0..linkerSymbol(usize, "RODATA_PAGES")) |_| {
        pt[i] = entry;
        i += 1;
        entry.raw += 0x1000;
    }

    entry.flags.writable = true;
    for (0..linkerSymbol(usize, "DATA_PAGES")) |_| {
        pt[i] = entry;
        i += 1;
        entry.raw += 0x1000;
    }

    entry.flags.nonExecutable = false;
    for (0..linkerSymbol(usize, "BSS_PAGES")) |_| {
        pt[i] = entry;
        i += 1;
        entry.raw += 0x1000;
    }

    pt[i] = TranslationEntry.init(0xb8000);
    pt[i].flags.writable = true;
    pt[i].flags.nonExecutable = true;

    setCr3(@intFromPtr(&pml4) - kernel_offset);
}

pub const TranslationEntry = packed union {
    raw: u64,
    flags: packed struct {
        present: bool,
        writable: bool,
        user: bool,
        padding: u60,
        nonExecutable: bool,
    },

    const Self = @This();

    const empty: Self = .{ .raw = 0 };

    pub fn init(addr: u64) Self {
        var self = TranslationEntry{ .raw = (addr & 0xfffffffffff00) };
        self.flags.present = true;
        return self;
    }
};

const TranslationTable = [512]TranslationEntry;

comptime {
    std.debug.assert(@sizeOf(TranslationTable) == 0x1000);
}

pub fn setCr3(top_level_translation_table: anytype) void {
    asm volatile (
        \\mov %[cr3], %%cr3
        :
        : [cr3] "r" (top_level_translation_table),
    );
}
