const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    // Build fuurin lib
    const fuurin_setup = b.addSystemCommand(&[_][]const u8{
        "cmake", "-B", "fuurin/build", "-S", "fuurin",
    });
    try fuurin_setup.step.make();
    const fuurin_build = b.addSystemCommand(&[_][]const u8{
        "cmake", "--build", "fuurin/build",
    });
    try fuurin_build.step.make();

    const exe = b.addExecutable("master_clock", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);

    // Add fuurin lib
    exe.addIncludeDir("fuurin/build/install/include");
    exe.addLibPath("fuurin/build/install/lib");
    exe.linkSystemLibrary("c");
    exe.linkSystemLibrary("c++");
    exe.linkSystemLibrary("fuurin_static");

    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
