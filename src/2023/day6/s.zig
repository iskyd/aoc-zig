const std = @import("std");
const utils = @import("../../utils.zig");
const FileReader = utils.FileReader;
const DelimiterFileWrapIterator = utils.DelimiterFileWrapIterator;
const LineNumberTextIterator = utils.LineNumberTextIterator;

fn getWinnings(time: u64, distance: u64) u64 {
    if (distance == 0) {
        return time - 2;
    }

    var winnings: u64 = 0;
    for (1..time - 1) |i| {
        if (i * (time - i) > distance) {
            winnings += 1;
        }
    }
    return winnings;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    const filename = args[1];

    var fullpath = try allocator.alloc(u8, 14 + args[1].len);
    defer allocator.free(fullpath);
    std.mem.copy(u8, fullpath[0..14], "src/2023/day6/");
    std.mem.copy(u8, fullpath[14..], filename);

    const reader = try FileReader.init(allocator, fullpath);
    defer reader.deinit();

    var iterator = DelimiterFileWrapIterator.init(reader.data, "\n");
    const times = std.mem.trim(u8, iterator.next().?[6..], " ");
    const distances = std.mem.trim(u8, iterator.next().?[9..], " ");

    var tit = LineNumberTextIterator(u64).init(times);
    var tdist = LineNumberTextIterator(u64).init(distances);
    var res: u64 = 1;
    while (tit.next()) |t| {
        var d: u64 = tdist.next().?;
        res *= getWinnings(t, d);
    }

    var size = std.mem.replacementSize(u8, times, " ", "");
    var st = allocator.alloc(u8, size) catch unreachable;
    _ = std.mem.replace(u8, times, " ", "", st);
    defer allocator.free(st);

    size = std.mem.replacementSize(u8, distances, " ", "");
    var sd = allocator.alloc(u8, size) catch unreachable;
    defer allocator.free(sd);
    _ = std.mem.replace(u8, distances, " ", "", sd);

    const t2 = std.fmt.parseInt(u64, st, 10) catch unreachable;
    const d2 = std.fmt.parseInt(u64, sd, 10) catch unreachable;

    var res2 = getWinnings(t2, d2);

    std.debug.print("Result: {d}\n", .{res});
    std.debug.print("Result part 2: {d}\n", .{res2});
}
