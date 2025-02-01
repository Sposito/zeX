const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Criando biblioteca estática `lib`
    const lib = b.addStaticLibrary(.{
        .name = "lib",
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Criando módulos separadamente
    const lib_module = b.addModule("lib", .{ .root_source_file = b.path("src/lib.zig") });
    const math_module = b.addModule("math", .{ .root_source_file = b.path("src/math.zig") });

    // Garantindo que `math` está acessível dentro de `lib`
    lib_module.addImport("math", math_module);
    lib.root_module.addImport("math", math_module);

    // Instalando `lib`
    b.installArtifact(lib);

    // Criando executável principal
    const exe = b.addExecutable(.{
        .name = "zeX",
        .root_source_file = b.path("src/zex.zig"),
        .target = target,
        .optimize = optimize,
    });

    // O executável precisa do módulo `lib`, que por sua vez já contém `math`
    exe.root_module.addImport("lib", lib_module);

    b.installArtifact(exe);

    // Passo para rodar a aplicação
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Testes
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("tests/tokenize.test.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Testes precisam importar `lib`
    lib_unit_tests.root_module.addImport("lib", lib_module);

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
