const std = @import("std");
const fmt = std.fmt;
const testing = std.testing;

pub fn parseJsonNumber(Type: type, input: []const u8) Type {
    _ = input;
    @panic("not implemented");
}

const JsonIntError = error{
    EmptyString,
    NoNumberFound,
    InvalidCharacter,
};

pub fn parseJsonPositiveInteger(input: []const u8) JsonIntError!struct { []const u8, usize } {
    if (input.len == 0) {
        return error.EmptyString;
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
        return error.NoNumberFound;
    }
    return .{ input[index..], result };
}

test "parse json positive integer - base case" {
    const expected = 42;
    const remaining = "other text";
    const actual = try parseJsonPositiveInteger("42other text");
    try testing.expectEqualStrings(remaining, actual[0]);
    try testing.expectEqual(expected, actual[1]);
}

test "parse json positive integer - empty string" {
    const expected = JsonIntError.EmptyString;
    const actual = parseJsonPositiveInteger("");
    try testing.expectEqual(expected, actual);
}

test "parse json positive integer - no number" {
    const expected = JsonIntError.NoNumberFound;
    const actual = parseJsonPositiveInteger("other text");
    try testing.expectEqual(expected, actual);
}

pub const JsonStringError = error{
    WrongDelimiters,
};

pub fn parseJsonString(input: []const u8) JsonStringError![]const u8 {
    return parseDelimited(skipSpace(input), '"', '"') catch JsonStringError.WrongDelimiters;
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

fn skipSpace(input: []const u8) []const u8 {
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

test "skip whitespace - base case" {
    const expected = "result value";
    const actual = skipSpace("  \n \t \r result value");
    try testing.expectEqualStrings(expected, actual);
}

test "skip whitespace - empty string" {
    const expected = "";
    const actual = skipSpace("");
    try testing.expectEqualStrings(expected, actual);
}

test "skip whitespace - only whitespace" {
    const expected = "";
    const actual = skipSpace("  \n \t \r ");
    try testing.expectEqualStrings(expected, actual);
}

test "skip whitespace - no whitespace" {
    const expected = "result value";
    const actual = skipSpace("result value");
    try testing.expectEqualStrings(expected, actual);
}

const DelimitedError = error{
    StartNotFound,
    EndNotFound,
};

fn parseDelimited(input: []const u8, start: u8, end: u8) DelimitedError![]const u8 {
    if (input[0] != start) {
        return DelimitedError.StartNotFound;
    }
    var count: usize = 1;
    var end_found = false;
    for (input[1..]) |char| {
        if (char == end) {
            end_found = true;
            break;
        }
        count += 1;
    }
    if (!end_found) {
        return DelimitedError.EndNotFound;
    }
    return input[1..count];
}

test "parse delimited - base case" {
    const expected = "result value";
    const actual = try parseDelimited("'result value'", '\'', '\'');
    try testing.expectEqualStrings(expected, actual);
}

test "parse delimited - empty value" {
    const expected = "";
    const actual = try parseDelimited("''", '\'', '\'');
    try testing.expectEqualStrings(expected, actual);
}

test "parse delimited - missing start" {
    const expected = DelimitedError.StartNotFound;
    const actual = parseDelimited(" '", '\'', '\'');
    try testing.expectEqual(expected, actual);
}

test "parse delimited - missing end" {
    const expected = DelimitedError.EndNotFound;
    const actual = parseDelimited("'", '\'', '\'');
    try testing.expectEqual(expected, actual);
}
