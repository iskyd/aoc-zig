const std = @import("std");
const ascii = std.ascii;
const utils = @import("../../utils.zig");
const FileReader = utils.FileReader;
const DelimiterFileWrapIterator = utils.DelimiterFileWrapIterator;

fn getWinningValue(text: []const u8) u16 {
    var it = std.mem.splitScalar(u8, text, ':');
    const game = it.next().?;
    const numbers = it.next().?;
    std.debug.print("Game: {s}\n", .{game});
    std.debug.print("Numbers: {s}\n", .{numbers});
    return 1;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    const filename = args[1];

    var fullpath = try allocator.alloc(u8, 14 + args[1].len);
    std.mem.copy(u8, fullpath[0..14], "src/2023/day4/");
    std.mem.copy(u8, fullpath[14..], filename);

    const reader = try FileReader.init(allocator, fullpath);
    defer reader.deinit();

    var iterator = DelimiterFileWrapIterator.init(reader.data, "\n");
    var result: u16 = 0;
    while (iterator.next()) |line| {
        result += getWinningValue(line);
    }

    std.debug.print("Result: {}\n", .{result});
}
