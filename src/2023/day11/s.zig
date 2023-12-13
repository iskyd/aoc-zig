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

    var emap = std.ArrayList(std.ArrayList(u8)).init(allocator); // Expandend map
    defer emap.deinit();
    for (map.items, 0..) |row, i| {
        var erow = std.ArrayList(u8).init(allocator);
        for (row.items, 0..) |val, j| {
            erow.append(val) catch unreachable;
            if (contains(ce, j)) {
                erow.append('.') catch unreachable;
            }
        }
        emap.append(erow) catch unreachable;
        if (contains(re, i)) {
            var erow2 = std.ArrayList(u8).init(allocator);
            for (0..erow.items.len) |_| {
                erow2.append('.') catch unreachable;
            }
            emap.append(erow2) catch unreachable;
        }
    }

    // Clean memory
    re.deinit();
    ce.deinit();
    for (map.items) |row| {
        row.deinit();
    }
    map.deinit();

    defer {
        for (emap.items) |row| {
            row.deinit();
        }
    }

    var galaxies = std.ArrayList(Galaxy).init(allocator);
    defer galaxies.deinit();
    for (emap.items, 0..) |row, i| {
        for (row.items, 0..) |val, j| {
            if (val == '#') {
                galaxies.append(Galaxy{ .x = i, .y = j }) catch unreachable;
            }
        }
    }

    // std.debug.print("Expanded map:\n", .{});
    // printMap(emap);

    var res: usize = 0;
    for (0..galaxies.items.len) |i| {
        for (i + 1..galaxies.items.len) |j| {
            var src = galaxies.items[i];
            var dst = galaxies.items[j];

            var distance = @abs(@as(i64, @intCast(src.x)) - @as(i64, @intCast(dst.x))) + @abs(@as(i64, @intCast(src.y)) - @as(i64, @intCast(dst.y)));
            res += distance;
        }
    }

    std.debug.print("Result {d}\n", .{res});
}
