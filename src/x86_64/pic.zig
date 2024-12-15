const io_ports = @import("io_ports.zig");

pub const master: Pic = .{ .command_port = 0x20, .data_port = 0x21 };
pub const slave: Pic = .{ .command_port = 0xA0, .data_port = 0xA1 };

const Pic = struct {
    command_port: u16,
    data_port: u16,

    const Self = @This();

    const master_mask: u8 = ~@as(u8, 0b0100);
    const slave_mask: u8 = ~@as(u8, 0);

    pub fn init(self: Self, options: Options) void {
        const icw1 = packed struct(u8) {
            icw4: bool = true,
            no_cascade: bool = false,
            unused1: u1 = undefined,
            no_edge: bool = false,
            init_command: bool = true,
            padding2: u3 = undefined,
        }{};
        io_ports.outb(self.command_port, @bitCast(icw1));
        io_ports.delay();
        io_ports.outb(self.data_port, options.vector_offset);
        io_ports.delay();
        io_ports.outb(self.data_port, if (options.chip == .master) 0b0100 else 2);
        io_ports.delay();
        io_ports.outb(self.data_port, 0b1);
        io_ports.delay();

        io_ports.outb(self.data_port, if (options.chip == .master) master_mask else slave_mask);
        io_ports.delay();
    }

    pub const Options = struct {
        chip: Chip,
        vector_offset: u8,
    };

    fn enableIrq(self: Self, irq: u3) void {
        var mask = io_ports.inb(self.data_port);
        mask &= ~(@as(u8, 1) << irq);
        io_ports.outb(self.data_port, mask);
    }

    fn disableIrq(self: Self, irq: u3) void {
        var mask = io_ports.inb(self.data_port);
        mask |= 1 << irq;
        io_ports.outb(self.data_port, mask);
    }

    fn sendEoi(self: Self) void {
        io_ports.outb(self.command_port, 0x20);
    }
};

pub const Chip = enum {
    master,
    slave,
};

pub const Device = enum(u4) {
    timer = 0,
    keyboard = 1,

    const Self = @This();

    fn pic(self: Self) Pic {
        return if (@intFromEnum(self) < 8) master else slave;
    }

    fn irq(self: Self) u3 {
        return @truncate(@intFromEnum(self));
    }

    pub fn enable(self: Self) void {
        self.pic().enableIrq(self.irq());
    }

    pub fn disable(self: Self) void {
        self.pic().disableIrq(self.irq());
    }

    pub fn sendEoi(self: Self) void {
        self.pic().sendEoi();
    }
};
