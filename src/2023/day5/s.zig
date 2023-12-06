const std = @import("std");
const utils = @import("../../utils.zig");
const FileReader = utils.FileReader;
const DelimiterFileWrapIterator = utils.DelimiterFileWrapIterator;

const Mapping = struct { destination: u32, source: u32, len: u32 };

fn addSeeds(seeds: *std.ArrayList(u32), line: []const u8) void {
    var it = std.mem.splitScalar(u8, line, ':');
    _ = it.next();
    var s = it.next().?;
    var it2 = std.mem.splitScalar(u8, std.mem.trim(u8, s, " "), ' ');
    while (it2.next()) |seed| {
        const n = std.fmt.parseInt(u32, std.mem.trim(u8, seed, " "), 10) catch unreachable;
        seeds.append(n) catch unreachable;
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    // defer std.debug.assert(gpa.deinit() == .ok);

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    const filename = args[1];

    var fullpath = try allocator.alloc(u8, 14 + args[1].len);
    defer allocator.free(fullpath);
    std.mem.copy(u8, fullpath[0..14], "src/2023/day5/");
    std.mem.copy(u8, fullpath[14..], filename);

    const reader = try FileReader.init(allocator, fullpath);
    defer reader.deinit();

    var iterator = DelimiterFileWrapIterator.init(reader.data, "\n\n");
    var seeds = std.ArrayList(u32).init(allocator);
    defer seeds.deinit();
    addSeeds(&seeds, iterator.next().?);
    // var mappings = std.ArrayList(std.AutoHashMap(u32, u32)).init(allocator);
    var mappings = std.ArrayList(std.ArrayList(Mapping)).init(allocator);
    defer mappings.deinit();
    while (iterator.next()) |section| {
        var it = std.mem.splitScalar(u8, section, '\n');
        _ = it.next();
        var m = std.ArrayList(Mapping).init(allocator);
        while (it.next()) |line| {
            var it2 = std.mem.splitScalar(u8, std.mem.trim(u8, line, " "), ' ');
            const drs = std.fmt.parseInt(u32, std.mem.trim(u8, it2.next().?, " "), 10) catch unreachable;
            const srs = std.fmt.parseInt(u32, std.mem.trim(u8, it2.next().?, " "), 10) catch unreachable;
            const rl = std.fmt.parseInt(u32, std.mem.trim(u8, it2.next().?, " "), 10) catch unreachable;
            m.append(Mapping{ .destination = drs, .source = srs, .len = rl }) catch unreachable;
        }
        mappings.append(m) catch unreachable;
    }

    defer {
        for (mappings.items) |*m| {
            m.deinit();
        }
    }

    var min: ?u32 = null;
    for (seeds.items) |seed| {
        var i: u32 = seed;
        for (mappings.items) |m1| {
            for (m1.items) |mapping| {
                if (mapping.source <= i and i <= mapping.source + mapping.len) {
                    i = mapping.destination + (i - mapping.source);
                    break;
                }
            }
        }
        if (min == null or i < min.?) {
            min = i;
        }
    }

    std.debug.print("Result: {?d}\n", .{min});
}
