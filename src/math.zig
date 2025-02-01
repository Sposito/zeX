const std = @import("std");

pub const Operator = enum {
    Add,
    Sub,
    Mul,
    Div,

    pub fn fromSymbol(symbol: []const u8) ?Operator {
        if (std.mem.eql(u8, symbol, "+")) return .Add;
        if (std.mem.eql(u8, symbol, "-")) return .Sub;
        if (std.mem.eql(u8, symbol, "*")) return .Mul;
        if (std.mem.eql(u8, symbol, "/")) return .Div;
        return null;
    }
};

pub fn add(comptime T: type, a: T, b: T) T {
    return a + b;
}

pub fn sub(comptime T: type, a: T, b: T) T {
    return a - b;
}

pub fn mul(comptime T: type, a: T, b: T) T {
    return a * b;
}

pub fn div(comptime T: type, a: T, b: T) T {
    return a / b;
}

pub fn applyOp(comptime op: Operator, comptime T: type, a: T, b: T) T {
    return switch (op) {
        .Add => add(T, a, b),
        .Sub => sub(T, a, b),
        .Mul => mul(T, a, b),
        .Div => div(T, a, b),
    };
}
