const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .x86_64,
        .os_tag = .freestanding,
        .abi = .none,
    });

    const exe = b.addExecutable(.{
        .name = "shellcode.elf",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/shellcode.zig"),
            .target = target,
            .optimize = .ReleaseSafe,
            .strip = true
        })
    });
    exe.pie = true;

    const bin = exe.addObjCopy(.{ .format = .bin });
    bin.only_section = ".text";


    const install_bin = b.addInstallBinFile(bin.getOutput(), "shellcode.bin");
    b.getInstallStep().dependOn(&install_bin.step);

}
