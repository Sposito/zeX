const std = @import("std");
const lib = @import("lib");
const testing = std.testing;

test "tokenize simple expression" {
    var allocator = testing.allocator;
    const source = "(define x 42)";
    const tokens = try lib.tokenize(allocator, source);
    defer allocator.free(tokens);

    const expected = [_][]const u8{
        "(", "define", "x", "42", ")",
    };

    try testing.expectEqual(@as(usize, expected.len), @as(usize, tokens.len));
    for (tokens, 0..) |token, i| {
        try testing.expect(std.mem.eql(u8, token, expected[i]));
    }
}
