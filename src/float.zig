const std = @import("std");
const testing = std.testing;
const util = @import("util.zig");

const JsonFloatError = error{
    EmptyInput,
    NoNumberFound,
    NumberInvalid,
};

pub fn parseJsonFloat(input: []const u8) JsonFloatError!struct { []const u8, f64 } {
    var text = input;
    const signResult = util.parseNumberSign(text);
    text = signResult[0];
    const sign = signResult[1];
    const integerResult = util.parseNumberCharsWithoutExtraZeros(text) catch |err| {
        return switch (err) {
            error.EmptyInput => error.EmptyInput,
            error.NoNumberChars => error.NoNumberFound,
            else => error.NumberInvalid,
        };
    };
    text = integerResult[0];
    const integerValue: f64 = @floatFromInt(integerResult[1]);
    const fractionalResult = util.parseFractionalNumberChars(integerResult[0]) catch {
        return .{ text, sign * integerValue };
    };
    text = fractionalResult[0];
    return .{ text, sign * integerValue + sign * fractionalResult[1] };
}

test "parseJsonFloat.baseCase" {
    const actual = try parseJsonFloat("12.34remaining string");
    try testing.expectEqualStrings("remaining string", actual[0]);
    try testing.expectEqual(12.34, actual[1]);
}

test "parseJsonFloat.negative" {
    const actual = try parseJsonFloat("-12.34remaining string");
    try testing.expectEqualStrings("remaining string", actual[0]);
    try testing.expectEqual(-12.34, actual[1]);
}
