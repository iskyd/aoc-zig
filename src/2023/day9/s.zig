const std = @import("std");
const utils = @import("../../utils.zig");
const ascii = std.ascii;
const FileReader = utils.FileReader;
const DelimiterFileWrapIterator = utils.DelimiterFileWrapIterator;
const LineNumberTextIterator = utils.LineNumberTextIterator;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    const filename = args[1];

    var fullpath = try allocator.alloc(u8, 14 + args[1].len);
    defer allocator.free(fullpath);
    std.mem.copy(u8, fullpath[0..14], "src/2023/day9/");
    std.mem.copy(u8, fullpath[14..], filename);

    const reader = try FileReader.init(allocator, fullpath);
    defer reader.deinit();

    var iterator = DelimiterFileWrapIterator.init(reader.data, "\n");
    var result: i64 = 0;
    var result2: i64 = 0;
    while (iterator.next()) |line| {
        var nit = LineNumberTextIterator(i64).init(line);
        var l = std.ArrayList(std.ArrayList(i64)).init(allocator);
        defer l.deinit();
        var l1 = std.ArrayList(i64).init(allocator);
        while (nit.next()) |n| {
            l1.append(n) catch unreachable;
        }
        l.append(l1) catch unreachable;

        while (true) {
            var current = l.items[l.items.len - 1];
            var cl = std.ArrayList(i64).init(allocator);
            var completed = true;
            for (0..current.items.len - 1) |i| {
                var res: i64 = current.items[i + 1] - current.items[i];
                if (res != 0) {
                    completed = false;
                }
                cl.append(res) catch unreachable;
            }
            l.append(cl) catch unreachable;
            if (completed == true) {
                break;
            }
        }

        defer {
            for (l.items) |*item| {
                item.deinit();
            }
        }

        l.items[l.items.len - 1].append(0) catch unreachable;
        var prevision: i64 = 0;
        for (1..l.items.len) |i| {
            var ci: std.ArrayList(i64) = l.items[l.items.len - i - 1];
            prevision += ci.items[ci.items.len - 1];
        }
        result += prevision;

        var bprevision: i64 = 0;
        for (1..l.items.len) |i| {
            var ci: std.ArrayList(i64) = l.items[l.items.len - i - 1];
            bprevision = ci.items[0] - bprevision;
        }
        result2 += bprevision;
    }

    std.debug.print("Result: {d}\n", .{result});
    std.debug.print("Result 2: {d}\n", .{result2});
}
