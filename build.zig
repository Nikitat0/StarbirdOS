const std = @import("std");
const Build = std.Build;
const Target = std.Target;

pub fn build(b: *Build) void {
    var disabled_features = Target.Cpu.Feature.Set.empty;
    var enabled_features = Target.Cpu.Feature.Set.empty;

    disabled_features.addFeature(@intFromEnum(Target.x86.Feature.x87));
    disabled_features.addFeature(@intFromEnum(Target.x86.Feature.mmx));
    disabled_features.addFeature(@intFromEnum(Target.x86.Feature.sse));
    disabled_features.addFeature(@intFromEnum(Target.x86.Feature.sse2));
    disabled_features.addFeature(@intFromEnum(Target.x86.Feature.avx));
    disabled_features.addFeature(@intFromEnum(Target.x86.Feature.avx2));
    enabled_features.addFeature(@intFromEnum(Target.x86.Feature.soft_float));

    const x86_64_freestanding = b.resolveTargetQuery(Target.Query{
        .cpu_arch = Target.Cpu.Arch.x86_64,
        .os_tag = Target.Os.Tag.freestanding,
        .abi = Target.Abi.none,
        .cpu_model = .{ .explicit = &Target.x86.cpu.x86_64 },
        .cpu_features_sub = disabled_features,
        .cpu_features_add = enabled_features,
    });
    const optimize = b.standardOptimizeOption(.{});

    const kernel_o = b.addExecutable(.{
        .name = "kernel.o",
        .root_source_file = b.path("src/root.zig"),
        .target = x86_64_freestanding,
        .optimize = optimize,
        .code_model = .kernel,
        .pic = false,
        .single_threaded = true,
        .link_libc = false,
        .strip = false,
    });
    kernel_o.entry = .{ .symbol_name = "startup" };
    kernel_o.root_module.addAnonymousImport(
        "logo",
        .{ .root_source_file = b.path("assets/logo.txt") },
    );
    kernel_o.bundle_compiler_rt = false;
    kernel_o.addObjectFile(addNasm(b, b.path("src/boot.nasm"), "boot.o"));
    kernel_o.addObjectFile(addNasm(b, b.path("src/lib.nasm"), "lib.o"));
    kernel_o.setLinkerScript(b.path("src/linker.ld"));

    b.getInstallStep().dependOn(&b.addInstallFile(kernel_o.getEmittedBin(), "kernel.o").step);

    const kernel_bin = b.addObjCopy(kernel_o.getEmittedBin(), .{ .format = .bin });

    b.getInstallStep().dependOn(&b.addInstallFile(kernel_bin.getOutput(), "kernel.bin").step);

    const init_o = b.addExecutable(.{
        .name = "init.o",
        .root_source_file = b.path("init/src/main.zig"),
        .target = x86_64_freestanding,
        .optimize = optimize,
        .code_model = .small,
        .pic = false,
        .single_threaded = true,
        .link_libc = false,
        .strip = false,
    });
    init_o.bundle_compiler_rt = false;
    init_o.entry = .{ .symbol_name = "main" };
    init_o.setLinkerScript(b.path("init/src/linker.ld"));

    b.getInstallStep().dependOn(&b.addInstallFile(init_o.getEmittedBin(), "init.o").step);

    const init_jedi = b.addObjCopy(init_o.getEmittedBin(), .{ .format = .bin });

    b.getInstallStep().dependOn(&b.addInstallFile(init_jedi.getOutput(), "init.jedi").step);

    const image = b.addSystemCommand(&.{"sh"});
    image.addFileArg(b.path("build_image.sh"));
    image.addFileArg(kernel_bin.getOutput());
    image.addFileArg(init_jedi.getOutput());
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

pub fn addNasm(b: *Build, source: Build.LazyPath, name: []const u8) Build.LazyPath {
    const boot = b.addSystemCommand(&.{ "nasm", "-f", "elf64", "-o" });
    const boot_o = boot.addOutputFileArg(name);
    boot.addFileArg(source);
    return boot_o;
}
