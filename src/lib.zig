const std = @import("std");
const math = @import("math");

const testing = std.testing;

pub const Expr = union(enum) {
    Number: i64,
    Symbol: []const u8,
    List: []const Expr,
};

pub fn tokenize(allocator: std.mem.Allocator, source: []const u8) ![]const []const u8 {
    var tokens = std.ArrayList([]const u8).init(allocator);
    defer tokens.deinit();

    var i: usize = 0;
    while (i < source.len) {
        const c = source[i];

        if (std.ascii.isWhitespace(c)) {
            i += 1;
            continue;
        }

        if (c == '(' or c == ')') {
            try tokens.append(source[i..i+1]);
            i += 1;
            continue;
        }

        if (c == ';') {
            while (i < source.len and source[i] != '\n') {
                i += 1;
            }
            continue;
        }

        if (c == '"') {
            const start = i;
            i += 1;
            while (i < source.len and source[i] != '"') {
                if (source[i] == '\\' and i + 1 < source.len) {
                    i += 2; // Pular escape (\")
                } else {
                    i += 1;
                }
            }
            if (i < source.len) {
                i += 1; // Incluir o fechamento da string
            }
            try tokens.append(source[start..i]);
            continue;
        }

        const start = i;
        while (i < source.len and !std.ascii.isWhitespace(source[i]) and source[i] != '(' and source[i] != ')' and source[i] != ';') {
            i += 1;
        }
        try tokens.append(source[start..i]);
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

pub fn generateZig(allocator: std.mem.Allocator, expr: Expr) ![]const u8 {
    return switch (expr) {
        .Number => |n| try std.fmt.allocPrint(allocator, "{d}", .{n}),
        .Symbol => |s| try allocator.dupe(u8, s),
        .List => |lst| blk: {
            if (lst.len == 0) break :blk "undefined";

            const func_name = try generateZig(allocator, lst[0]);

            const op = math.Operator.fromSymbol(func_name);

            var args = std.ArrayList([]const u8).init(allocator);
            defer args.deinit();

            for (lst[1..]) |arg| {
                try args.append(try generateZig(allocator, arg));
            }

            if (op) |operation| {
                if (args.items.len != 2) return error.InvalidArity;
                break :blk try std.fmt.allocPrint(
                    allocator, 
                    "math.applyOp(.{s}, i64, {s}, {s})", 
                    .{@tagName(operation), args.items[0], args.items[1]}
                );
            }

            const joined_args = try std.mem.join(allocator, ", ", args.items);
            break :blk try std.fmt.allocPrint(allocator, "{s}({s})", .{ func_name, joined_args });
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
