const utils = @import("./utils.zig");
const inb = utils.inb;
const outb = utils.outb;

pub const master_pic: Pic = .{ .commandPort = 0x20, .dataPort = 0x21 };
pub const slave_pic: Pic = .{ .commandPort = 0xA0, .dataPort = 0xA1 };

const Pic = struct {
    commandPort: u16,
    dataPort: u16,

    const Self = @This();

    const master_mask: u8 = ~@as(u8, 0b0100);
    const slave_mask: u8 = ~@as(u8, 0);

    pub fn init(self: Self, options: Options) void {
        const icw1 = packed struct {
            icw4: bool = true,
            noCascade: bool = true,
            unused1: u1 = undefined,
            noEdge: bool = true,
            initCommand: bool = true,
            padding2: u3 = undefined,
        }{};
        outb(self.commandPort, @bitCast(icw1));
        utils.delay();
        outb(self.dataPort, options.vectorOffset);
        utils.delay();
        outb(self.dataPort, if (options.chip == .master) 0b0100 else 2);
        utils.delay();
        outb(self.dataPort, 0b1);
        utils.delay();

        outb(self.dataPort, if (options.chip == .master) master_mask else slave_mask);
        utils.delay();
    }

    pub const Options = struct {
        chip: Chip,
        vectorOffset: u8,
    };

    fn enableIrq(self: Self, irq: u3) void {
        var mask = inb(self.dataPort);
        mask &= ~(@as(u8, 1) << irq);
        outb(self.dataPort, mask);
    }

    fn disableIrq(self: Self, irq: u3) void {
        var mask = inb(self.dataPort);
        mask |= 1 << irq;
        outb(self.dataPort, mask);
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
        return if (@intFromEnum(self) < 8) master_pic else slave_pic;
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
};
