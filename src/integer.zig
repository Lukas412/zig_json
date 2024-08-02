const std = @import("std");
const testing = std.testing;
const util = @import("util.zig");

const JsonIntError = error{
    EmptyInput,
    NoNumberFound,
    NumberInvalid,
};

pub fn parseJsonPositiveInt(input: []const u8) JsonIntError!struct { []const u8, usize } {
    return util.parseNumberCharsWithoutExtraZeros(input) catch |err| {
        return switch (err) {
            error.EmptyInput => JsonIntError.EmptyInput,
            error.NoNumberChars => JsonIntError.NoNumberFound,
            else => JsonIntError.NumberInvalid,
        };
    };
}

test "parseJsonPositiveInteger.baseCase" {
    const actual = try parseJsonPositiveInt("42other text");
    try testing.expectEqualStrings("other text", actual[0]);
    try testing.expectEqual(42, actual[1]);
}

test "parseJsonPositiveInteger.emptyString" {
    const actual = parseJsonPositiveInt("");
    try testing.expectEqual(JsonIntError.EmptyInput, actual);
}

test "parseJsonPositiveInteger.noNumber" {
    const actual = parseJsonPositiveInt("other text");
    try testing.expectEqual(JsonIntError.NoNumberFound, actual);
}
