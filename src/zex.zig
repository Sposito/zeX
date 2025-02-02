const std = @import("std");
const lib = @import("lib");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // Código Scheme de entrada
    const scheme_source = "(+ (+ 1 2) 3)";

    // Tokeniza e parseia a entrada
    const tokens = try lib.tokenize(allocator, scheme_source);
    var index: usize = 0;
    const expr = try lib.parse(tokens, &index, allocator);

    // Transforma a AST em um tipo Zig para avaliação em tempo de compilação
    const Computed = lib.generateZig(expr);

    // Executa a expressão em `comptime`
    comptime {
        std.debug.print("Resultado: {}\n", .{Computed.eval()});
    }
}
