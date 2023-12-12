const std = @import("std");
const assert = std.debug.assert;

pub const FileReader = struct {
    allocator: std.mem.Allocator,
    path: []const u8,
    data: []const u8,

    pub fn init(allocator: std.mem.Allocator, path: []const u8) !FileReader {
        const data = try std.fs.cwd().readFileAlloc(allocator, path, std.math.maxInt(usize));
        return FileReader{ .allocator = allocator, .path = path, .data = data };
    }

    pub fn deinit(self: FileReader) void {
        self.allocator.free(self.data);
    }

    pub fn rows(self: FileReader, delimiter: []const u8) u16 {
        var result: u16 = 1;
        for (0..self.data.len) |i| {
            if (self.data[i] == delimiter[0]) {
                result += 1;
            }
        }
        return result;
    }

    pub fn cols(self: FileReader, delimiter: []const u8) u16 {
        var result: u16 = 0;
        for (0..self.data.len) |i| {
            result += 1;
            if (self.data[i] == delimiter[0]) {
                return result;
            }
        }
        unreachable;
    }
};

pub const DelimiterFileWrapIterator = struct {
    text: []const u8,
    delimiter: []const u8,
    current: u64,

    pub fn init(text: []const u8, delimiter: []const u8) DelimiterFileWrapIterator {
        return DelimiterFileWrapIterator{ .text = text, .delimiter = delimiter, .current = 0 };
    }

    pub fn next(self: *DelimiterFileWrapIterator) ?[]const u8 {
        if (self.text.len == 0 or self.current >= self.text.len) {
            return null;
        }

        const delimiterIndex = std.mem.indexOf(u8, self.text[self.current..], self.delimiter);
        if (delimiterIndex == null) {
            const result = self.text[self.current..];
            self.current = self.text.len;
            return result;
        }

        const result = self.text[self.current .. self.current + delimiterIndex.?];
        self.current = self.current + delimiterIndex.? + self.delimiter.len;
        return result;
    }
};

pub fn LineNumberTextIterator(comptime K: type) type {
    return struct {
        text: []const u8,
        current: u64,

        pub fn init(text: []const u8) LineNumberTextIterator(K) {
            return LineNumberTextIterator(K){ .text = text, .current = 0 };
        }

        pub fn next(self: *LineNumberTextIterator(K)) ?K {
            if (self.text.len == 0 or self.current >= self.text.len) {
                return null;
            }

            var start = self.current;
            while (true) {
                if (self.text[start] == '\n') {
                    return null;
                } else if (self.text[start] == ' ') {
                    start += 1;
                } else {
                    break;
                }
            }
            var end = start;
            while (true) {
                if (self.text.len == end) {
                    break;
                } else if (std.ascii.isDigit(self.text[end]) or self.text[end] == '-') {
                    end += 1;
                } else {
                    break;
                }
            }
            self.current = end + 1;
            return std.fmt.parseInt(K, self.text[start..end], 10) catch unreachable;
        }
    };
}
