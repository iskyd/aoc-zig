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
