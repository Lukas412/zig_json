const std = @import("std");
const testing = std.testing;
const util = @import("util.zig");
const NumberCharsError = util.NumberCharsError;

const JsonIntError = error{
    EmptyInput,
    NoNumberFound,
    NumberInvalid,
};

pub fn parseJsonInt(input: []const u8) JsonIntError!struct { []const u8, isize } {
    const signResult = util.parseNumberSign(isize, input) orelse return JsonIntError.EmptyInput;
    const intResult = util.parseNumberCharsWithoutExtraZeros(signResult[0]) catch |err| {
        return switch (err) {
            NumberCharsError.EmptyInput => JsonIntError.EmptyInput,
            NumberCharsError.NoNumberChars => JsonIntError.NoNumberFound,
            else => JsonIntError.NumberInvalid,
        };
    };
    const intValue: isize = @intCast(intResult[1]);
    return .{ intResult[0], signResult[1] * intValue };
}

test "parseJsonInt.baseCase" {
    const actual = try parseJsonInt("-123remaining text");
    try testing.expectEqualStrings("remaining text", actual[0]);
    try testing.expectEqual(-123, actual[1]);
}

test "parseJsonInt.emptyString" {
    const actual = parseJsonInt("");
    try testing.expectError(JsonIntError.EmptyInput, actual);
}

pub fn parseJsonPositiveInt(input: []const u8) JsonIntError!struct { []const u8, usize } {
    return util.parseNumberCharsWithoutExtraZeros(input) catch |err| {
        return switch (err) {
            NumberCharsError.EmptyInput => JsonIntError.EmptyInput,
            NumberCharsError.NoNumberChars => JsonIntError.NoNumberFound,
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
