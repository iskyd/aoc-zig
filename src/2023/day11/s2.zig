const std = @import("std");
const utils = @import("../../utils.zig");
const ascii = std.ascii;
const FileReader = utils.FileReader;
const DelimiterFileWrapIterator = utils.DelimiterFileWrapIterator;

const Galaxy = struct { x: usize, y: usize };

fn contains(l: std.ArrayList(usize), n: usize) bool {
    for (l.items) |i| {
        if (i == n) {
            return true;
        }
    }
    return false;
}

fn printMap(map: std.ArrayList(std.ArrayList(u8))) void {
    for (map.items) |row| {
        for (row.items) |val| {
            std.debug.print("{c}", .{val});
        }
        std.debug.print("\n", .{});
    }
}

fn emptyRows(re: std.ArrayList(usize), i: usize, j: usize) usize {
    var start: usize = 0;
    var end: usize = 0;
    if (i > j) {
        start = j;
        end = i;
    } else {
        start = i;
        end = j;
    }
    var res: usize = 0;
    for (start..end) |k| {
        if (contains(re, k)) {
            res += 1;
        }
    }

    return res;
}

fn emptyCols(ce: std.ArrayList(usize), i: usize, j: usize) usize {
    var start: usize = 0;
    var end: usize = 0;
    if (i > j) {
        start = j;
        end = i;
    } else {
        start = i;
        end = j;
    }
    var res: usize = 0;
    for (start..end) |k| {
        if (contains(ce, k)) {
            res += 1;
        }
    }

    return res;
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
    std.mem.copy(u8, fullpath[0..15], "src/2023/day11/");
    std.mem.copy(u8, fullpath[15..], filename);

    const reader = try FileReader.init(allocator, fullpath);
    defer reader.deinit();

    var iterator = DelimiterFileWrapIterator.init(reader.data, "\n");
    var map = std.ArrayList(std.ArrayList(u8)).init(allocator);
    defer map.deinit();
    defer {
        for (map.items) |row| {
            row.deinit();
        }
    }
    while (iterator.next()) |line| {
        var l = std.ArrayList(u8).init(allocator);
        for (0..line.len) |i| {
            l.append(line[i]) catch unreachable;
        }
        map.append(l) catch unreachable;
    }

    // Expand the map
    var re = std.ArrayList(usize).init(allocator); // Rows to expand
    var ce = std.ArrayList(usize).init(allocator); // Columns to expand
    defer re.deinit();
    defer ce.deinit();
    for (map.items, 0..) |row, i| {
        var rhasgalaxy = false;
        for (row.items) |val| {
            if (val == '#') {
                rhasgalaxy = true;
                break;
            }
        }
        if (rhasgalaxy == false) {
            re.append(i) catch unreachable;
        }
    }
    for (0..map.items[0].items.len) |i| {
        var chasgalaxy = false;
        for (map.items) |row| {
            if (row.items[i] == '#') {
                chasgalaxy = true;
                break;
            }
        }
        if (chasgalaxy == false) {
            ce.append(i) catch unreachable;
        }
    }

    var galaxies = std.ArrayList(Galaxy).init(allocator);
    defer galaxies.deinit();
    for (map.items, 0..) |row, i| {
        for (row.items, 0..) |val, j| {
            if (val == '#') {
                galaxies.append(Galaxy{ .x = i, .y = j }) catch unreachable;
            }
        }
    }

    // std.debug.print("Map:\n", .{});
    // printMap(map);

    var res: usize = 0;
    for (0..galaxies.items.len) |i| {
        for (i + 1..galaxies.items.len) |j| {
            var src = galaxies.items[i];
            var dst = galaxies.items[j];

            var er = emptyRows(re, src.x, dst.x);
            var ec = emptyCols(ce, src.y, dst.y);

            var distance = @abs(@as(i64, @intCast(src.x)) - @as(i64, @intCast(dst.x))) + @abs(er * 1000000 - er) + @abs(@as(i64, @intCast(src.y)) - @as(i64, @intCast(dst.y))) + (ec * 1000000 - ec);
            res += distance;
        }
    }

    std.debug.print("Result {d}\n", .{res});
}
