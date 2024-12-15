pub const Table = [512]TableEntry;

pub const empty_table = .{TableEntry.not_present} ** 512;

pub const TableEntry = packed union {
    raw: u64,
    flags: packed struct(u64) {
        present: bool,
        writable: bool,
        user: bool,
        padding: u60,
        nonExecutable: bool,
    },

    const Self = @This();

    const not_present: Self = .{ .raw = 0 };

    pub fn init(addr: u64) Self {
        var self = TableEntry{ .raw = (addr & 0xfffffffffff00) };
        self.flags.present = true;
        return self;
    }
};

pub fn setTopLevelTable(top_level_table: anytype) void {
    asm volatile (
        \\mov %[cr3], %%cr3
        :
        : [cr3] "r" (top_level_table),
    );
}

pub const VirtualAddress = packed struct(u64) {
    page_offset: u12,
    pt_index: u9,
    pd_index: u9,
    pdp_index: u9,
    pml4_index: u9,
    sign_extenstion: u16,

    const Self = @This();

    pub fn examine(virt_addr: anytype) Self {
        return @bitCast(virt_addr);
    }
};
