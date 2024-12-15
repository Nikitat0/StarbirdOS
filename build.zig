const std = @import("std");

pub fn build(b: *std.Build) void {
    var disabled_features = std.Target.Cpu.Feature.Set.empty;
    var enabled_features = std.Target.Cpu.Feature.Set.empty;

    disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.x87));
    disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.mmx));
    disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.sse));
    disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.sse2));
    disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.avx));
    disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.avx2));
    enabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.soft_float));

    const x86_64_freestanding = b.resolveTargetQuery(std.Target.Query{
        .cpu_arch = std.Target.Cpu.Arch.x86_64,
        .os_tag = std.Target.Os.Tag.freestanding,
        .abi = std.Target.Abi.none,
        .cpu_model = .{ .explicit = &std.Target.x86.cpu.x86_64 },
        .cpu_features_sub = disabled_features,
        .cpu_features_add = enabled_features,
    });
    const optimize = b.standardOptimizeOption(.{});

    const kernel_o = b.addExecutable(.{
        .name = "kernel.elf",
        .root_source_file = b.path("src/main.zig"),
        .target = x86_64_freestanding,
        .optimize = optimize,
        .code_model = .kernel,
        .pic = false,
        .single_threaded = true,
        .link_libc = false,
        .strip = false,
    });
    kernel_o.bundle_compiler_rt = false;
    kernel_o.addObjectFile(addNasm(b, b.path("src/boot.nasm"), "boot.o"));
    kernel_o.addObjectFile(addNasm(b, b.path("src/lib.nasm"), "lib.o"));
    kernel_o.setLinkerScript(b.path("src/linker.ld"));

    b.getInstallStep().dependOn(&b.addInstallFile(kernel_o.getEmittedBin(), "kernel.o").step);

    const kernel_bin = b.addObjCopy(kernel_o.getEmittedBin(), .{ .format = .bin });

    b.getInstallStep().dependOn(&b.addInstallFile(kernel_bin.getOutput(), "kernel.bin").step);

    const image = b.addSystemCommand(&.{"sh"});
    image.addFileArg(b.path("src/build_image.sh"));
    image.addFileArg(kernel_bin.getOutput());
    const boot_img = image.addOutputFileArg("boot.img");

    b.getInstallStep().dependOn(&b.addInstallFile(boot_img, "boot.img").step);

    const opt_nodisplay = b.option(
        bool,
        "nodisplay",
        "Do not display video output. The kernel will still see emulated VGA graphics",
    ) orelse false;
    const opt_monitor = b.option(bool, "monitor", "Enable QEMU monitor") orelse false;

    const run_image = b.addSystemCommand(&.{ "qemu-system-x86_64", "-fda" });
    run_image.addFileArg(boot_img);
    run_image.addArgs(&.{ "-display", if (opt_nodisplay) "none" else "gtk,full-screen=on" });
    if (opt_monitor)
        run_image.addArgs(&.{ "-monitor", "stdio" });
    if (b.args) |args| {
        run_image.addArgs(args);
    }

    const run_step = b.step("run", "Run the kernel in QEMU");
    run_step.dependOn(&run_image.step);
}

pub fn addNasm(b: *std.Build, source: std.Build.LazyPath, name: []const u8) std.Build.LazyPath {
    const boot = b.addSystemCommand(&.{ "nasm", "-f", "elf64", "-o" });
    const boot_o = boot.addOutputFileArg(name);
    boot.addFileArg(source);
    return boot_o;
}
