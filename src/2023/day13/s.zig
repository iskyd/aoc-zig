const std = @import("std");
const utils = @import("../../utils.zig");
const ascii = std.ascii;
const FileReader = utils.FileReader;
const DelimiterFileWrapIterator = utils.DelimiterFileWrapIterator;

fn reflectVertical(pattern: std.ArrayList(std.ArrayList(u8)), mid: usize) bool {
    var diff = utils.minUsize(mid, pattern.items[0].items.len - mid);
    var s1 = mid - diff;
    var s2 = mid + diff - 1;
    while (s1 < s2) {
        for (0..pattern.items.len) |i| {
            if (pattern.items[i].items[s1] != pattern.items[i].items[s2]) {
                return false;
            }
        }
        s1 += 1;
        s2 -= 1;
    }
    return true;
}

fn reflectHorizontal(pattern: std.ArrayList(std.ArrayList(u8)), mid: usize) bool {
    var diff = utils.minUsize(mid, pattern.items.len - mid);
    var s1 = mid - diff;
    var s2 = mid + diff - 1;
    while (s1 < s2) {
        for (0..pattern.items[0].items.len) |i| {
            if (pattern.items[s1].items[i] != pattern.items[s2].items[i]) {
                return false;
            }
        }
        s1 += 1;
        s2 -= 1;
    }
    return true;
}

fn reflectionValue(pattern: std.ArrayList(std.ArrayList(u8))) usize {
    var result: usize = 0;
    for (1..pattern.items[0].items.len) |i| {
        if (reflectVertical(pattern, i)) {
            result += i;
            break;
        }
    }

    for (1..pattern.items.len) |i| {
        if (reflectHorizontal(pattern, i)) {
            result += i * 100;
            break;
        }
    }

    return result;
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
    std.mem.copy(u8, fullpath[0..15], "src/2023/day13/");
    std.mem.copy(u8, fullpath[15..], filename);

    const reader = try FileReader.init(allocator, fullpath);
    defer reader.deinit();

    var iterator = DelimiterFileWrapIterator.init(reader.data, "\n\n");
    var result: usize = 0;
    while (iterator.next()) |p| {
        var pattern = std.ArrayList(std.ArrayList(u8)).init(allocator);
        defer pattern.deinit();
        var lit = DelimiterFileWrapIterator.init(p, "\n");
        while (lit.next()) |line| {
            var row = std.ArrayList(u8).init(allocator);
            for (line) |c| {
                row.append(c) catch unreachable;
            }
            pattern.append(row) catch unreachable;
        }

        result += reflectionValue(pattern);

        defer {
            for (pattern.items) |item| {
                item.deinit();
            }
        }
    }

    std.debug.print("Result: {d}\n", .{result});
}
