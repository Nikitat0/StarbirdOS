pub const Header = extern struct {
    magic_number: u32 = 0x6964656a,
    version: u32 = 0,
    text_pages: usize,
    rodata_pages: usize,
    data_pages: usize,
    bss_pages: usize,

    const Self = @This();

    pub fn bssPageOffset(self: Self) usize {
        return self.text_pages + self.rodata_pages + self.data_pages;
    }
};
