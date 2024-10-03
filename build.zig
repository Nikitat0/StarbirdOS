const std = @import("std");

pub fn build(b: *std.Build) void {
    var disabled_features = std.Target.Cpu.Feature.Set.empty;
    var enabled_features = std.Target.Cpu.Feature.Set.empty;

    disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.mmx));
    disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.sse));
    disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.sse2));
    disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.avx));
    disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.avx2));
    disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.avx2));
    enabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.soft_float));

    const x86_64_freestanfing = b.resolveTargetQuery(std.Target.Query{
        .cpu_arch = std.Target.Cpu.Arch.x86_64,
        .os_tag = std.Target.Os.Tag.freestanding,
        .abi = std.Target.Abi.none,
        .cpu_features_sub = disabled_features,
        .cpu_features_add = enabled_features,
    });
    const optimize = b.standardOptimizeOption(.{});

    const kernel_elf = b.addExecutable(.{
        .name = "kernel.elf",
        .root_source_file = b.path("src/main.zig"),
        .target = x86_64_freestanfing,
        .optimize = optimize,
        .code_model = .kernel,
        .single_threaded = true,
    });
    kernel_elf.setLinkerScript(b.path("src/linker.ld"));

    const kernel_bin = b.addObjCopy(kernel_elf.getEmittedBin(), .{ .format = .bin });

    const boot = b.addSystemCommand(&.{ "nasm", "-f", "bin", "-o" });
    const boot_bin = boot.addOutputFileArg("boot.bin");
    boot.addFileArg(b.path("src/boot.nasm"));

    const image = b.addSystemCommand(&.{"sh"});
    image.addFileArg(b.path("src/build_image.sh"));
    image.addFileArg(boot_bin);
    image.addFileArg(kernel_bin.getOutput());
    const boot_img = image.addOutputFileArg("boot.img");

    b.getInstallStep().dependOn(&b.addInstallFile(boot_img, "boot.img").step);

    const opt_nodisplay = b.option(
        bool,
        "nodisplay",
        "Do not display video output. The kernel will still VGA graphics",
    ) orelse false;
    const opt_monitor = b.option(bool, "monitor", "Enable QEMU monitor") orelse false;

    const run_image = b.addSystemCommand(&.{ "qemu-system-x86_64", "-fda" });
    run_image.addFileArg(boot_img);
    run_image.addArgs(&.{ "-display", if (opt_nodisplay) "none" else "gtk,full-screen=on" });
    if (opt_monitor)
        run_image.addArgs(&.{ "-monitor", "stdio" });

    const run_step = b.step("run", "Run the kernel in QEMU");
    run_step.dependOn(&run_image.step);
}
