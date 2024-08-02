const std = @import("std");
const math = std.math;
const testing = std.testing;

pub fn skipSpace(input: []const u8) []const u8 {
    var count: usize = 0;
    for (input) |char| {
        switch (char) {
            ' ', '\t', '\n', '\r' => {
                count += 1;
            },
            else => break,
        }
    }
    return input[count..];
}

test "skipWhitespace.baseCase" {
    const actual = skipSpace("  \n \t \r result value");
    try testing.expectEqualStrings("result value", actual);
}

test "skipWhitespace.emptyString" {
    const actual = skipSpace("");
    try testing.expectEqualStrings("", actual);
}

test "skipWhitespace.onlyWhitespace" {
    const actual = skipSpace("  \n \t \r ");
    try testing.expectEqualStrings("", actual);
}

test "skipWhitespace.noWhitespace" {
    const actual = skipSpace("result value");
    try testing.expectEqualStrings("result value", actual);
}

pub const DelimitedError = error{
    StartNotFound,
    EndNotFound,
};

pub fn parseDelimited(input: []const u8, start: u8, end: u8) DelimitedError![]const u8 {
    if (input[0] != start) {
        return error.StartNotFound;
    }
    for (input[1..], 1..) |char, index| {
        if (char == end) {
            return input[1..index];
        }
    }
    return error.EndNotFound;
}

test "parseDelimited.baseCase" {
    const actual = try parseDelimited("'result value'", '\'', '\'');
    try testing.expectEqualStrings("result value", actual);
}

test "parseDelimited.emptyValue" {
    const actual = try parseDelimited("''", '\'', '\'');
    try testing.expectEqualStrings("", actual);
}

test "parseDelimited.missingStart" {
    const actual = parseDelimited(" '", '\'', '\'');
    try testing.expectEqual(DelimitedError.StartNotFound, actual);
}

test "parseDelimited.missingEnd" {
    const actual = parseDelimited("'", '\'', '\'');
    try testing.expectEqual(DelimitedError.EndNotFound, actual);
}

pub fn skipDelimited(input: []const u8, start: u8, end: u8) DelimitedError![]const u8 {
    if (input[0] != start) {
        return error.StartNotFound;
    }
    for (input[1..], 1..) |char, index| {
        if (char == end) {
            return input[(index + 1)..];
        }
    }
    return error.EndNotFound;
}

test "skipDelimited.baseCase" {
    const actual = try skipDelimited("'some text'remaining text", '\'', '\'');
    try testing.expectEqualStrings("remaining text", actual);
}

test "skipDelimited.missingStart" {
    const actual = skipDelimited("some text'remaining text", '\'', '\'');
    try testing.expectEqual(error.StartNotFound, actual);
}

test "skipDelimited.missingEnd" {
    const actual = skipDelimited("'some textremaining text", '\'', '\'');
    try testing.expectEqual(error.EndNotFound, actual);
}

pub const NumberCharsError = error{
    EmptyInput,
    NoNumberChars,
    NumberStartsWithExtraZero,
    FractionNotStartingWithDot,
};

pub fn parseNumberChars(input: []const u8) NumberCharsError!struct { []const u8, usize } {
    if (input.len == 0) {
        return error.EmptyInput;
    }
    if ('0' > input[0] or input[0] > '9') {
        return error.NoNumberChars;
    }
    var index: usize = 1;
    var result: usize = input[0] - '0';
    for (input[1..]) |char| {
        if ('0' > char or char > '9') {
            break;
        }
        result *= 10;
        result += (char - '0');
        index += 1;
    }
    return .{ input[index..], result };
}

test "parseNumberChars.baseCase" {
    const actual = try parseNumberChars("0123remaining text");
    try testing.expectEqualStrings("remaining text", actual[0]);
    try testing.expectEqual(123, actual[1]);
}

test "parseNumberChars.zero" {
    const actual = try parseNumberChars("0remaining text");
    try testing.expectEqualStrings("remaining text", actual[0]);
    try testing.expectEqual(0, actual[1]);
}

test "parseNumberChars.emptyInput" {
    const actual = parseNumberChars("");
    try testing.expectEqual(error.EmptyInput, actual);
}

test "parseNumberChars.noNumberChars" {
    const actual = parseNumberChars("remaining text");
    try testing.expectEqual(error.NoNumberChars, actual);
}

pub fn parseNumberCharsWithoutExtraZeros(input: []const u8) NumberCharsError!struct { []const u8, usize } {
    if (input.len == 0) {
        return error.EmptyInput;
    }
    if (input[0] == '0') {
        if (input.len >= 2 and '0' <= input[1] and input[1] <= '9') {
            return error.NumberStartsWithExtraZero;
        }
        return .{ input[1..], 0 };
    }
    var index: usize = 0;
    var result: usize = 0;
    for (input) |char| {
        if ('0' > char or char > '9') {
            break;
        }
        result *= 10;
        result += (char - '0');
        index += 1;
    }
    if (index == 0) {
        return NumberCharsError.NoNumberChars;
    }
    return .{ input[index..], result };
}

test "parseNumberCharsWithoutExtraZeros.baseCase" {
    const actual = try parseNumberCharsWithoutExtraZeros("42remaining text");
    try testing.expectEqualStrings("remaining text", actual[0]);
    try testing.expectEqual(42, actual[1]);
}

test "parseNumberCharsWithoutExtraZeros.zero" {
    const actual = try parseNumberCharsWithoutExtraZeros("0remaining text");
    try testing.expectEqualStrings("remaining text", actual[0]);
    try testing.expectEqual(0, actual[1]);
}
test "parseNumberCharsWithoutExtraZeros.noNumberChars" {
    const actual = parseNumberCharsWithoutExtraZeros("remaining text");
    try testing.expectEqual(error.NoNumberChars, actual);
}

test "parseNumberCharsWithoutExtraZeros.numberStartingWithZero" {
    const actual = parseNumberCharsWithoutExtraZeros("042remaining text");
    try testing.expectEqual(error.NumberStartsWithExtraZero, actual);
}

pub fn parseFractionalNumberChars(input: []const u8) NumberCharsError!struct { []const u8, f64 } {
    if (input.len == 0) {
        return error.EmptyInput;
    }
    if (input[0] != '.') {
        return error.FractionNotStartingWithDot;
    }
    if ('0' > input[1] or input[1] > '9') {
        return .{ input[1..], 0.0 };
    }
    var index: usize = 1;
    var result: f64 = 0;
    for (input[1..]) |char| {
        if ('0' > char or char > '9') {
            break;
        }
        var part: f64 = @floatFromInt(char - '0');
        part /= math.pow(f64, 10, @floatFromInt(index));
        result += part;
        index += 1;
    }
    return .{ input[index..], result };
}

test "parseFractionalNumberChars.baseCase" {
    const actual = try parseFractionalNumberChars(".123remaining text");
    try testing.expectEqualStrings("remaining text", actual[0]);
    const rounded = @round(actual[1] * 1000) / 1000;
    try testing.expectEqual(0.123, rounded);
}

test "parseFractionalNumberChars.emptyInput" {
    const actual = parseFractionalNumberChars("");
    try testing.expectEqual(error.EmptyInput, actual);
}

test "parseFractionalNumberChars.notStartingWithDot" {
    const actual = parseFractionalNumberChars("123remaining text");
    try testing.expectEqual(error.FractionNotStartingWithDot, actual);
}

test "parseFractionNumberChars.noNumberChars" {
    const actual = try parseFractionalNumberChars(".remaining text");
    try testing.expectEqualStrings("remaining text", actual[0]);
    try testing.expectEqual(0, actual[1]);
}

pub fn parseNumberSign(T: type, input: []const u8) ?struct { []const u8, T } {
    if (input.len == 0) {
        return null;
    }
    return switch (input[0]) {
        '-' => .{ input[1..], -1 },
        '+' => .{ input[1..], 1 },
        else => .{ input, 1 },
    };
}

test "parseNumberSign.baseCase" {
    const actual = parseNumberSign(f64, "-123") orelse @panic("should not be reached");
    try testing.expectEqualStrings("123", actual[0]);
    try testing.expectEqual(-1.0, actual[1]);
}

test "parseNumberSign.withoutSign" {
    const actual = parseNumberSign(f64, "123") orelse @panic("should not be reached");
    try testing.expectEqualStrings("123", actual[0]);
    try testing.expectEqual(1.0, actual[1]);
}

pub fn expectEqualFloats(expected: f64, actual: f64) !void {
    const expectedRounded = @round(expected * 10000) / 10000;
    const actualRounded = @round(actual * 10000) / 10000;
    try testing.expectEqual(expectedRounded, actualRounded);
}
