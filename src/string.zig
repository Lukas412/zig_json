const std = @import("std");
const testing = std.testing;
const util = @import("util.zig");

pub const JsonStringError = error{
    WrongDelimiters,
};

pub fn parseJsonString(input: []const u8) JsonStringError![]const u8 {
    return util.parseDelimited(util.skipSpace(input), '"', '"') catch JsonStringError.WrongDelimiters;
}

test "parse json string - base case" {
    const expected = "string value";
    const actual = try parseJsonString("\"string value\"");
    try testing.expectEqualStrings(expected, actual);
}

test "parse json string - with whitespace" {
    const expected = "string value";
    const actual = try parseJsonString("  \"string value\"");
    try testing.expectEqualStrings(expected, actual);
}

test "parse json string - without start" {
    const expected = JsonStringError.WrongDelimiters;
    const actual = parseJsonString("  string value\"");
    try testing.expectEqual(expected, actual);
}

test "parse json string - without end" {
    const expected = JsonStringError.WrongDelimiters;
    const actual = parseJsonString("  \"string value");
    try testing.expectEqual(expected, actual);
}
