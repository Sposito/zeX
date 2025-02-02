const std = @import("std");
const math = @import("math");

const testing = std.testing;

pub const Expr = union(enum) {
    Number: i64,
    Symbol: []const u8,
    List: []const Expr,

    pub fn newNumber(value: i64) Expr {
        return .{ .Number = value };
    }

    pub fn newSymbol(arena: *std.mem.ArenaAllocator, symbol: []const u8) !Expr {
        const buffer = try arena.alloc(u8, symbol.len);
        std.mem.copy(u8, buffer, symbol);
        return .{ .Symbol = buffer };
    }

    pub fn newList(arena: *std.mem.ArenaAllocator, items: []const Expr) !Expr {
        const copy = try arena.alloc(Expr, items.len);
        std.mem.copy(Expr, copy, items);
        // The slice we store in .List now lives in the arena's memory.
        return .{ .List = copy[0..items.len] };
    }
};

pub fn ComputedExpr(comptime T: type) type {
    return struct {
        pub fn eval(a: T, b: T) T {
            return a + b;
        }
    };
}

pub fn tokenize(allocator: std.mem.Allocator, source: []const u8) ![]const []const u8 {
    var tokens = std.ArrayList([]const u8).init(allocator);

    var i: usize = 0;
    while (i < source.len) {
        const c = source[i];

        // Skip whitespace
        if (std.ascii.isWhitespace(c)) {
            i += 1;
            continue;
        }

        // Parentheses become individual tokens "(" or ")"
        if (c == '(' or c == ')') {
            try tokens.append(source[i..i+1]);
            i += 1;
            continue;
        }

        // Semicolons start a comment until end of line
        if (c == ';') {
            while (i < source.len and source[i] != '\n') {
                i += 1;
            }
            continue;
        }

        if (c == '"') {
            i += 1;
            var builder = std.ArrayList(u8).init(allocator);

            while (i < source.len and source[i] != '"') {

                if (source[i] == '\\' and (i + 1) < source.len) {
                    const next_char = source[i + 1];
                    switch (next_char) {
                        'n' => try builder.append("\n"),
                        't' => try builder.append("\t"),
                        'r' => try builder.append("\r"),
                        '"' => try builder.append('"'),
                        '\\' => try builder.append('\\'),
                        else => {
                            try builder.append(next_char);
                        },
                    }
                    i += 2;
                } else {
                    try builder.append(source[i]);
                    i += 1;
                }
            }

            if (i < source.len and source[i] == '"') {
                i += 1;
            } else {
                return error.UnterminatedString;
            }

            const str_token = try builder.toOwnedSlice();
            try tokens.append(str_token);

            builder.deinit();
            continue;
        }

        const start = i;
        while (
            i < source.len
            and !std.ascii.isWhitespace(source[i])
            and source[i] != '('
            and source[i] != ')'
            and source[i] != ';'
            and source[i] != '"'
        ) {
            i += 1;
        }
        if (i > start) {
            try tokens.append(source[start..i]);
        }
    }

    return tokens.toOwnedSlice();
}




pub fn parse(tokens: []const []const u8, index: *usize, allocator: std.mem.Allocator) !Expr {
    if (index.* >= tokens.len) return error.UnexpectedEOF;

    if (tokens[index.*][0] == '(') {
        index.* += 1;
        var list = std.ArrayList(Expr).init(allocator);
        defer list.deinit();

        while (index.* < tokens.len and tokens[index.*][0] != ')') {
            try list.append(try parse(tokens, index, allocator));
        }

        if (index.* >= tokens.len or tokens[index.*][0] != ')') {
            return error.UnmatchedParentheses;
        }

        index.* += 1;
        return .{ .List = try list.toOwnedSlice() };
    } else {
        const token = tokens[index.*];
        index.* += 1;

        if (std.fmt.parseInt(i64, token, 10)) |num| {
            return .{ .Number = num };
        } else |_| {
            return .{ .Symbol = token };
        }
    }
}

pub fn generateZig(comptime expr: Expr) type {
    return switch (expr) {
        .Number => struct {
            pub fn eval() comptime_int {
                return expr.Number;
            }
        },
        .List => |lst| blk: {
            if (lst.len == 0) break :blk struct {};
            const func_name = lst[0];

            if (math.Operator.fromSymbol(func_name.Symbol)) |operation| {
                if (lst.len != 3) @compileError("Invalid arity for operator");

                const T = comptime_int;
                const lhs = generateZig(lst[1]);
                const rhs = generateZig(lst[2]);

                break :blk struct {
                    pub fn eval() T {
                        return math.applyOp(operation, T, lhs.eval(), rhs.eval());
                    }
                };
            }

            @compileError("Unknown function: " ++ func_name.Symbol);
        }
    };
}


pub fn writeToFile(filename: []const u8, content: []const u8) !void {
    var file = try std.fs.cwd().createFile(filename, .{ .truncate = true });
    defer file.close();
    try file.writeAll(content);
}

pub fn compileGeneratedZig() !void {
    const zig_cmd = "zig build-exe output.zig -O ReleaseSafe -o output";
    _ = std.process.Child.run(.{ .allocator = std.heap.page_allocator, .argv = &[_][]const u8{ "sh", "-c", zig_cmd } }) catch  unreachable;

}
