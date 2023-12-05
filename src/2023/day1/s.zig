const std = @import("std");
const ascii = std.ascii;
const utils = @import("../../utils.zig");
const FileReader = utils.FileReader;
const DelimiterFileWrapIterator = utils.DelimiterFileWrapIterator;

pub fn getCalibrationValue(text: []const u8) u8 {
    var first: ?u8 = null;
    var last: ?u8 = null;
    for (text) |char| {
        if (ascii.isDigit(char)) {
            if (first == null) {
                first = char - '0';
            }

            last = char - '0';
        }
    }

    var buf: [2]u8 = undefined;
    _ = std.fmt.bufPrint(&buf, "{d}{d}", .{ first.?, last.? }) catch unreachable;
    var cv: u8 = std.fmt.parseInt(u8, &buf, 10) catch unreachable;

    return cv;
}

pub fn fixCalibrationValue(allocator: std.mem.Allocator, text: []const u8) []u8 {
    const strnumbers = [10][]const u8{
        "zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
    };
    const replace = [10][]const u8{
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
    };

    var previous = allocator.alloc(u8, text.len) catch unreachable;
    @memcpy(previous, text);

    for (strnumbers, 0..) |str, i| {
        var replacement = allocator.alloc(u8, 1 + str.len + str.len) catch unreachable;
        _ = std.fmt.bufPrint(replacement, "{s}{s}{s}", .{ str, replace[i], str }) catch unreachable;
        var size = std.mem.replacementSize(u8, previous, str, replacement);
        var tmp = allocator.alloc(u8, size) catch unreachable;
        _ = std.mem.replace(u8, previous, str, replacement, tmp);
        allocator.free(previous);
        previous = allocator.alloc(u8, size) catch unreachable;
        @memcpy(previous, tmp);
    }

    return previous;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    const filename = args[1];
    const applyFix = args.len > 2;

    var fullpath = try allocator.alloc(u8, 14 + args[1].len);
    defer allocator.free(fullpath);
    std.mem.copy(u8, fullpath[0..14], "src/2023/day1/");
    std.mem.copy(u8, fullpath[14..], filename);

    const reader = try FileReader.init(allocator, fullpath);
    defer reader.deinit();

    var iterator: DelimiterFileWrapIterator = undefined;
    if (applyFix) {
        const fixed = fixCalibrationValue(allocator, reader.data);
        iterator = DelimiterFileWrapIterator.init(fixed, "\n");
    } else {
        iterator = DelimiterFileWrapIterator.init(reader.data, "\n");
    }
    var sum: u32 = 0;
    while (iterator.next()) |line| {
        var cv: u8 = getCalibrationValue(line);
        sum += cv;
    }

    std.debug.print("Result: {}\n", .{sum});
}
