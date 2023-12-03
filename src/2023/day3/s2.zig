const std = @import("std");
const ascii = std.ascii;
const utils = @import("../../utils.zig");
const FileReader = utils.FileReader;
const DelimiterFileWrapIterator = utils.DelimiterFileWrapIterator;

fn gearPosition(text: []const u8, rows: u16, cols: u16, start: usize, end: usize) ?usize {
    _ = rows;
    if (start >= 1) {
        if (text[start - 1] == '*') {
            return start - 1;
        }
    }

    if (end < text.len) {
        if (text[end + 1] == '*') {
            return end + 1;
        }
    }

    if (start > cols) {
        var ss = start - cols;
        var es = end - cols + 1;
        if (ss % cols != 0) {
            ss -= 1;
        }
        if (es > cols and (es - cols) % cols != 0) {
            es += 1;
        }

        for (ss..es) |i| {
            if (text[i] == '*') {
                return i;
            }
        }
    }

    if (end + cols < text.len) {
        var ss = start + cols;
        var es = end + cols + 1;
        if (ss % cols != 0) {
            ss -= 1;
        }
        if ((es - cols) % cols != 0) {
            es += 1;
        }

        for (ss..es) |i| {
            if (text[i] == '*') {
                return i;
            }
        }
    }

    return null;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    const filename = args[1];

    var fullpath = try allocator.alloc(u8, 14 + args[1].len);
    std.mem.copy(u8, fullpath[0..14], "src/2023/day3/");
    std.mem.copy(u8, fullpath[14..], filename);

    const reader = try FileReader.init(allocator, fullpath);
    defer reader.deinit();

    var numbers = std.ArrayList(u16).init(allocator); // numbers near a gear
    var gears = std.ArrayList(usize).init(allocator); // gear positions
    var hm = std.AutoHashMap(usize, usize).init(allocator);
    defer numbers.deinit();
    defer gears.deinit();

    const rows = reader.rows("\n");
    const cols = reader.cols("\n");
    for (0..rows) |row| {
        var start: ?usize = null;
        var end: ?usize = null;
        for (0..cols) |col| {
            var idx = row * cols + col;
            if (idx >= reader.data.len) break; // This is needed because the last don't have a \n so it's shorter

            if (ascii.isDigit(reader.data[idx])) {
                if (start == null) {
                    start = idx;
                }
                end = idx;
            } else {
                if (start != null and end != null) {
                    const gear = gearPosition(reader.data, rows, cols, start.?, end.?);
                    if (gear != null) {
                        const n = std.fmt.parseInt(u16, reader.data[start.? .. end.? + 1], 10) catch unreachable;
                        numbers.append(n) catch unreachable;
                        gears.append(gear.?) catch unreachable;
                        var v = try hm.getOrPut(gear.?);
                        if (v.found_existing == false) {
                            v.value_ptr.* = 1;
                        } else {
                            v.value_ptr.* += 1;
                        }
                    }
                }

                start = null;
                end = null;
            }
        }
    }

    var result: u32 = 0;
    var keyIter = hm.keyIterator();
    while (keyIter.next()) |key| {
        if (hm.get(key.*) == 2) {
            var ratio: u32 = 1;
            for (0..numbers.items.len) |i| {
                if (gears.items[i] == key.*) {
                    ratio *= numbers.items[i];
                }
            }
            result += ratio;
        }
    }

    std.debug.print("Result {d}\n", .{result});
}
