const std = @import("std");
const utils = @import("../../utils.zig");
const ascii = std.ascii;
const FileReader = utils.FileReader;
const DelimiterFileWrapIterator = utils.DelimiterFileWrapIterator;

fn roll(map: *std.ArrayList(std.ArrayList(u8))) void {
    for (0..map.items.len - 1) |i| {
        for (0..map.items[0].items.len) |j| {
            var currow = map.items.len - i - 1;
            var bestrow: usize = currow;
            var el = map.items[currow].items[j];
            if (el == 'O') {
                var prevrow = currow - 1;
                var prev = map.items[prevrow].items[j];
                while (prev != '#') {
                    if (prev == '.') {
                        bestrow = prevrow;
                    }
                    if (prevrow > 0) {
                        prevrow -= 1;
                        prev = map.items[prevrow].items[j];
                    } else {
                        break;
                    }
                }
            }
            if (bestrow != currow) {
                map.items[bestrow].items[j] = 'O';
                map.items[currow].items[j] = '.';
            }
        }
    }
}

fn calculateLoad(map: std.ArrayList(std.ArrayList(u8))) usize {
    var rows: usize = map.items.len;
    var load: usize = 0;
    for (0..rows) |i| {
        for (0..map.items[0].items.len) |j| {
            if (map.items[i].items[j] == 'O') {
                load += rows - i;
            }
        }
    }

    return load;
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
    std.mem.copy(u8, fullpath[0..15], "src/2023/day14/");
    std.mem.copy(u8, fullpath[15..], filename);

    const reader = try FileReader.init(allocator, fullpath);
    defer reader.deinit();

    var iterator = DelimiterFileWrapIterator.init(reader.data, "\n");
    var map = std.ArrayList(std.ArrayList(u8)).init(allocator);
    defer map.deinit();
    while (iterator.next()) |line| {
        var row = std.ArrayList(u8).init(allocator);
        for (line) |c| {
            row.append(c) catch unreachable;
        }
        map.append(row) catch unreachable;
    }
    defer {
        for (map.items) |row| {
            row.deinit();
        }
    }

    roll(&map);

    std.debug.print("Load: {d}\n", .{calculateLoad(map)});
}
