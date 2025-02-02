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

    // FIX: Removed unnecessary @intCast()
    try testing.expectEqual(expected.len, tokens.len);

    for (tokens, 0..) |token, i| {
        try testing.expect(std.mem.eql(u8, token, expected[i]));
    }
}

// test "tokenize with comments" {
//     var allocator = testing.allocator;

//     // Ensure each line ends with `++` for proper concatenation
//     const source =
//         "(define y 10) ; comment about y\n" ++
//         "(define z 20) ; another comment\n"; // Ensure this line ends correctly

//     const tokens = try lib.tokenize(allocator, source);
//     defer allocator.free(tokens);

//     const expected = [_][]const u8{
//         "(", "define", "y", "10", ")",
//         "(", "define", "z", "20", ")",
//     };

//     try testing.expectEqual(expected.len, tokens.len);

//     for (tokens, 0..) |token, i| {
//         try testing.expect(std.mem.eql(u8, token, expected[i]));
//     }
// }




// test "tokenize strings" {
//     var allocator = testing.allocator;
//     const source = "(display \"Hello \\\"World\\\"\\n\")";
//     const tokens = try lib.tokenize(allocator, source);
//     defer allocator.free(tokens);

//     std.debug.print("Tokens found:\n", .{});
//     for (tokens, 0..) |token, i| {
//         std.debug.print("Token {d}: '{s}'\n", .{ i, token });
//     }

//     const expected = [_][]const u8{
//         "(", "display", "Hello \\\"World\\\"\\n", ")"
//     };

//     try testing.expectEqual(expected.len, tokens.len);

//     for (tokens, 0..) |token, i| {
//         try testing.expect(std.mem.eql(u8, token, expected[i]));
//     }
// }



// test "tokenize nested parentheses with whitespace" {
//     var allocator = testing.allocator;
//     const source = 
//         "(begin (define   (foo) (bar baz))  )"; // Fixed the formatting

//     const tokens = try lib.tokenize(allocator, source);
//     defer allocator.free(tokens);

//     const expected = [_][]const u8{
//         "(", "begin", "(", "define", "(", "foo", ")", "(", "bar", "baz", ")", ")", ")"
//     };

//     // Corrected `testing.expectEqual` usage
//     try testing.expectEqual(expected.len, tokens.len); // No need for `@intCast`
    
//     for (tokens, 0..) |token, i| {
//         try testing.expect(std.mem.eql(u8, token, expected[i]));
//     }
// }


// test "tokenize unterminated string" {
//     var allocator = testing.allocator;
//     const source = "(display \"Hello World )"; // Unterminated string

//     const result = lib.tokenize(allocator, source);

//     if (result) |tokens| {
//         defer allocator.free(tokens);
//         std.debug.print("Unexpected tokens:\n", .{});
//         for (tokens, 0..) |token, i| {
//             std.debug.print("Token {d}: '{s}'\n", .{ i, token });
//         }
//         try testing.expect(false); // Fail the test
//     } else |err| {
//         std.debug.print("Error received: {}\n", .{err});
//         try testing.expectEqual(error.UnterminatedString, err);
//     }
// }




