const std = @import("std");
const utils = @import("../../utils.zig");
const ascii = std.ascii;
const FileReader = utils.FileReader;
const DelimiterFileWrapIterator = utils.DelimiterFileWrapIterator;

fn calculateHash(str: []const u8) usize {
    var val: usize = 0;
    for (0..str.len) |i| {
        var char: usize = @as(usize, str[i]);
        val += char;
        val *= 17;
        val = @mod(val, 256);
    }

    return val;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    const filename = args[1];

    var fullpath = try allocator.alloc(u8, 15 + args[1].len);
    defer allocator.free(fullpath);
    std.mem.copy(u8, fullpath[0..15], "src/2023/day15/");
    std.mem.copy(u8, fullpath[15..], filename);

    const reader = try FileReader.init(allocator, fullpath);
    defer reader.deinit();

    var iterator = DelimiterFileWrapIterator.init(reader.data, ",");
    var result: usize = 0;
    while (iterator.next()) |str| {
        var h = calculateHash(str);
        result += h;
    }
    std.debug.print("Result: {d}\n", .{result});
}
