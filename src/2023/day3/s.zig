const std = @import("std");
const ascii = std.ascii;
const utils = @import("../../utils.zig");
const FileReader = utils.FileReader;
const DelimiterFileWrapIterator = utils.DelimiterFileWrapIterator;

fn nearSymbol(text: []const u8, rows: u16, cols: u16, start: usize, end: usize) bool {
    _ = rows;
    if (start >= 1) {
        if (text[start - 1] != '.' and text[start - 1] != '\n') {
            return true;
        }
    }

    if (end < text.len) {
        if (text[end + 1] != '.' and text[end + 1] != '\n') {
            return true;
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
            if (text[i] != '.' and text[i] != '\n') {
                return true;
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
            if (text[i] != '.' and text[i] != '\n') {
                return true;
            }
        }
    }

    return false;
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
    std.mem.copy(u8, fullpath[0..14], "src/2023/day3/");
    std.mem.copy(u8, fullpath[14..], filename);

    const reader = try FileReader.init(allocator, fullpath);
    defer reader.deinit();

    var result: u32 = 0;
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
                    // Parse the number and check if it's near a symbol
                    if (nearSymbol(reader.data, rows, cols, start.?, end.?)) {
                        const n = std.fmt.parseInt(u16, reader.data[start.? .. end.? + 1], 10) catch unreachable;
                        result += n;
                    }
                }

                start = null;
                end = null;
            }
        }
    }

    std.debug.print("Result {d}\n", .{result});
}
