const std = @import("std");
const utils = @import("../../utils.zig");
const ascii = std.ascii;
const FileReader = utils.FileReader;
const DelimiterFileWrapIterator = utils.DelimiterFileWrapIterator;

// We can apply this only to square matrix which is our case
fn rotate(map: *std.ArrayList(std.ArrayList(u8))) void {
    // Transpose
    for (0..map.items.len) |i| {
        for (i + 1..map.items.len) |j| {
            var tmp = map.items[i].items[j];
            map.items[i].items[j] = map.items[j].items[i];
            map.items[j].items[i] = tmp;
        }
    }

    // Reverse
    for (0..map.items.len) |i| {
        for (0..map.items.len / 2) |j| {
            var tmp = map.items[i].items[j];
            map.items[i].items[j] = map.items[i].items[map.items.len - j - 1];
            map.items[i].items[map.items.len - j - 1] = tmp;
        }
    }
}

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

fn printMap(map: std.ArrayList(std.ArrayList(u8))) void {
    for (map.items) |row| {
        for (row.items) |el| {
            std.debug.print("{c}", .{el});
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("\n", .{});
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

fn contains(seen: std.ArrayList(std.ArrayList(std.ArrayList(u8))), map: std.ArrayList(std.ArrayList(u8))) ?usize {
    var found = true;
    var idx: usize = 0;
    for (seen.items) |item| {
        found = true;
        for (0..item.items.len) |i| {
            for (0..item.items[0].items.len) |j| {
                if (item.items[i].items[j] != map.items[i].items[j]) {
                    found = false;
                    break;
                }
            }
            if (found == false) {
                break;
            }
        }
        if (found == true) {
            return idx;
        }
        idx += 1;
    }
    return null;
}

fn copyMap(allocator: std.mem.Allocator, map: std.ArrayList(std.ArrayList(u8))) std.ArrayList(std.ArrayList(u8)) {
    var newmap = std.ArrayList(std.ArrayList(u8)).init(allocator);
    for (map.items) |row| {
        var newrow = std.ArrayList(u8).init(allocator);
        for (row.items) |el| {
            newrow.append(el) catch unreachable;
        }
        newmap.append(newrow) catch unreachable;
    }
    return newmap;
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

    var seen = std.ArrayList(std.ArrayList(std.ArrayList(u8))).init(allocator);
    defer seen.deinit();
    var c = copyMap(allocator, map);
    seen.append(c) catch unreachable;

    var cycle: usize = 0;
    var idx: ?usize = null;
    while (true) {
        // Cycle
        cycle += 1;
        for (0..4) |i| {
            _ = i;
            roll(&map);
            rotate(&map);
        }
        idx = contains(seen, map);
        if (idx != null) {
            break;
        }
        var cloned = copyMap(allocator, map);
        seen.append(cloned) catch unreachable;
    }

    defer {
        for (seen.items) |s| {
            for (s.items) |t| {
                t.deinit();
            }
            s.deinit();
        }
    }
    var midx = @mod(1000000000 - idx.?, cycle - idx.?) + idx.?;
    var fmap = seen.items[midx];

    std.debug.print("Load: {d}\n", .{calculateLoad(fmap)});
}
