const std = @import("std");
const ascii = std.ascii;
const utils = @import("../../utils.zig");
const FileReader = utils.FileReader;
const DelimiterFileWrapIterator = utils.DelimiterFileWrapIterator;

fn getWinningValue(allocator: std.mem.Allocator, text: []const u8) u16 {
    var it = std.mem.splitScalar(u8, text, ':');
    _ = it.next().?;
    const numbers = it.next().?;
    var it2 = std.mem.splitScalar(u8, std.mem.trim(u8, numbers, " "), '|');
    var s1 = it2.next().?;
    var s2 = it2.next().?;
    var w = std.mem.splitScalar(u8, std.mem.trim(u8, s1, " "), ' ');
    var d = std.mem.splitScalar(u8, std.mem.trim(u8, s2, " "), ' ');
    var hm = std.AutoHashMap(u16, u16).init(allocator);
    defer hm.deinit();

    while (w.next()) |wn| {
        if (std.mem.eql(u8, std.mem.trim(u8, wn, " "), "")) {
            continue;
        }
        const n = std.fmt.parseInt(u16, std.mem.trim(u8, wn, " "), 10) catch unreachable;
        var v = hm.getOrPut(n) catch unreachable;
        if (v.found_existing == false) {
            v.value_ptr.* = 0;
        }
        v.value_ptr.* += 1;
    }

    var res: u16 = 0;
    while (d.next()) |dn| {
        if (std.mem.eql(u8, std.mem.trim(u8, dn, " "), "")) {
            continue;
        }
        const n = std.fmt.parseInt(u16, std.mem.trim(u8, dn, " "), 10) catch unreachable;
        if (hm.get(n) != null) {
            res = switch (res) {
                0 => 1,
                else => res << 1,
            };
        }
    }

    return res;
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
        result += getWinningValue(allocator, line);
    }

    std.debug.print("Result: {}\n", .{result});
}
