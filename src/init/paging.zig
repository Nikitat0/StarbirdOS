const std = @import("std");

const linkage = @import("root").linkage;

const x86_64 = @import("root").x86_64;
const cr = x86_64.cr;
const msr = x86_64.msr;
const paging = x86_64.paging;

var pml4: paging.Table align(4096) = paging.empty_table;
var pdp: paging.Table align(4096) = paging.empty_table;
var pd: paging.Table align(4096) = paging.empty_table;
var pt: paging.Table align(4096) = paging.empty_table;

pub fn init() void {
    @memset(linkage.symbol([*]u8, "BSS_BEGIN")[0..linkage.value("BSS_SIZE")], 0);

    var cr0 = cr.read(cr.@"0");
    cr0.wp = true;
    cr.write(cr0);

    var efer = msr.read(msr.Efer);
    efer.nxe = true;
    msr.write(efer);

    const kernel_offset = paging.VirtualAddress.examine(linkage.value("KERNEL_OFFSET"));

    pml4[kernel_offset.pml4_index] = paging.TableEntry.init(linkage.loadAddr(&pdp));
    pml4[kernel_offset.pml4_index].flags.writable = true;
    pdp[kernel_offset.pdp_index] = paging.TableEntry.init(linkage.loadAddr(&pd));
    pdp[kernel_offset.pdp_index].flags.writable = true;
    pd[kernel_offset.pd_index] = paging.TableEntry.init(linkage.loadAddr(&pt));
    pd[kernel_offset.pd_index].flags.writable = true;

    var i: usize = kernel_offset.pt_index;
    var entry = paging.TableEntry.init(0);

    entry.flags.writable = true;
    entry.flags.nonExecutable = true;
    for (0..linkage.value("STACK_PAGES")) |_| {
        pt[i] = entry;
        i += 1;
        entry.raw += 0x1000;
    }

    entry.flags.writable = false;
    entry.flags.nonExecutable = false;
    for (0..linkage.value("TEXT_PAGES")) |_| {
        pt[i] = entry;
        i += 1;
        entry.raw += 0x1000;
    }

    entry.flags.nonExecutable = true;
    for (0..linkage.value("RODATA_PAGES")) |_| {
        pt[i] = entry;
        i += 1;
        entry.raw += 0x1000;
    }

    entry.flags.writable = true;
    for (0..linkage.value("DATA_PAGES")) |_| {
        pt[i] = entry;
        i += 1;
        entry.raw += 0x1000;
    }

    entry.flags.nonExecutable = false;
    for (0..linkage.value("BSS_PAGES")) |_| {
        pt[i] = entry;
        i += 1;
        entry.raw += 0x1000;
    }

    pt[i] = paging.TableEntry.init(0xb8000);
    pt[i].flags.writable = true;
    pt[i].flags.nonExecutable = true;

    paging.setTopLevelTable(linkage.loadAddr(&pml4));
}
