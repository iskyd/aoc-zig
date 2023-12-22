const std = @import("std");
const utils = @import("../../utils.zig");
const ascii = std.ascii;
const FileReader = utils.FileReader;
const DelimiterFileWrapIterator = utils.DelimiterFileWrapIterator;

const CacheKey = struct {
    start: u8,
    s: usize,
    c: usize,
};

fn contains(needle: u8, haystack: []const u8) bool {
    for (haystack) |c| {
        if (c == needle) {
            return true;
        }
    }
    return false;
}

var cache: std.AutoHashMap(CacheKey, usize) = undefined;

fn count(spring: []const u8, config: []usize) usize {
    if (spring.len == 0) {
        if (config.len == 0) {
            return 1;
        }
        return 0;
    }
    if (config.len == 0) {
        if (contains('#', spring) == true) {
            return 0;
        }
        return 1;
    }

    var result: usize = 0;

    var key = CacheKey{
        .start = spring[0],
        .s = spring.len,
        .c = config.len,
    };

    var cached = cache.get(key);
    if (cached != null) {
        return cached.?;
    }

    if (spring[0] == '.' or spring[0] == '?') {
        result += count(spring[1..], config);
    }

    if (spring[0] == '#' or spring[0] == '?') {
        if (config[0] <= spring.len and contains('.', spring[0..config[0]]) == false and (config[0] == spring.len or spring[config[0]] != '#')) {
            if (config[0] == spring.len) {
                result += count(spring[config[0]..], config[1..]);
            } else {
                result += count(spring[config[0] + 1 ..], config[1..]);
            }
        }
    }
    cache.put(key, result) catch unreachable;

    return result;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    // defer std.debug.assert(gpa.deinit() == .ok);

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    const filename = args[1];

    var fullpath = try allocator.alloc(u8, 15 + args[1].len);
    defer allocator.free(fullpath);
    std.mem.copy(u8, fullpath[0..15], "src/2023/day12/");
    std.mem.copy(u8, fullpath[15..], filename);

    const reader = try FileReader.init(allocator, fullpath);
    defer reader.deinit();

    var iterator = DelimiterFileWrapIterator.init(reader.data, "\n");
    var result: usize = 0;
    while (iterator.next()) |line| {
        var it = std.mem.split(u8, line, " ");
        var spring = it.next().?;
        var config = it.next().?;
        var cit = std.mem.split(u8, config, ",");
        var l: usize = 0;
        while (cit.next()) |_| : (l += 1) {}
        cit.reset();
        var slice = allocator.alloc(usize, l * 5) catch unreachable;
        defer allocator.free(slice);
        var index: usize = 0;
        for (0..5) |_| {
            while (cit.next()) |n| : (index += 1) {
                var num: usize = std.fmt.parseInt(usize, n, 10) catch unreachable;
                slice[index] = num;
            }
            cit.reset();
        }
        var es = allocator.alloc(u8, spring.len * 5 + 4) catch unreachable;
        defer allocator.free(es);
        var start: usize = 0;
        var end: usize = spring.len;
        for (0..5) |_| {
            std.mem.copy(u8, es[start..end], spring);
            if (end < es.len) {
                es[end] = '?';
            }
            start = end + 1;
            end = start + spring.len;
        }

        cache = std.AutoHashMap(CacheKey, usize).init(allocator);
        defer cache.deinit();
        result += count(es, slice);
    }
    std.debug.print("Result: {d}\n", .{result});
}
