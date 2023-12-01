const std = @import("std");
const FileReader = @import("../../utils.zig").FileReader;
const DelimiterFileWrapIterator = @import("../../utils.zig").DelimiterFileWrapIterator;
const ascii = @import("std").ascii;

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

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    const filename = args[1];

    var fullpath = try allocator.alloc(u8, 14 + args[1].len);
    std.mem.copy(u8, fullpath[0..14], "src/2023/day1/");
    std.mem.copy(u8, fullpath[14..], filename);

    const reader = try FileReader.init(allocator, fullpath);
    defer reader.deinit();

    var iterator = DelimiterFileWrapIterator.init(reader.data, "\n");
    var sum: u32 = 0;
    while (iterator.next()) |line| {
        var cv: u8 = getCalibrationValue(line);
        sum += cv;
    }

    std.debug.print("Sum: {}\n", .{sum});
}
