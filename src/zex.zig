const std = @import("std");
const lib = @import("lib");

// Função principal
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // Código Scheme de entrada
    const scheme_source = "(+ (+ 1 2) 3)";

    const tokens = try lib.tokenize(allocator, scheme_source);
    var index: usize = 0;
    const expr = try lib.parse(tokens, &index, allocator);

    const zig_code = try lib.generateZig(allocator, expr);

    try lib.writeToFile("output.zig", zig_code);
    try lib.compileGeneratedZig();

    std.debug.print("Executável gerado: ./output\n", .{});
}
