const std = @import("std");
const utils = @import("../../utils.zig");
const ascii = std.ascii;
const FileReader = utils.FileReader;
const DelimiterFileWrapIterator = utils.DelimiterFileWrapIterator;

const Node = struct {
    left: []u8,
    right: []u8,
};

fn gcd(a: u64, b: u64) u64 {
    if (b == 0) {
        return a;
    }
    return gcd(b, a % b);
}

fn lcm(a: u64, b: u64) u64 {
    return (a / gcd(a, b)) * b;
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
    std.mem.copy(u8, fullpath[0..14], "src/2023/day8/");
    std.mem.copy(u8, fullpath[14..], filename);

    const reader = try FileReader.init(allocator, fullpath);
    defer reader.deinit();

    var iterator = DelimiterFileWrapIterator.init(reader.data, "\n\n");
    var instructions = iterator.next().?;
    var section = iterator.next().?;

    var it2 = DelimiterFileWrapIterator.init(section, "\n");
    var hm = std.StringHashMap(Node).init(allocator);
    defer hm.deinit();
    while (it2.next()) |line| {
        var val = allocator.dupe(u8, line[0..3]) catch unreachable;
        var left = allocator.dupe(u8, line[7..10]) catch unreachable;
        var right = allocator.dupe(u8, line[12..15]) catch unreachable;
        hm.put(val, Node{ .left = left, .right = right }) catch unreachable;
    }
    defer {
        var it = hm.valueIterator();
        while (it.next()) |el| {
            allocator.free(el.left);
            allocator.free(el.right);
        }
    }
    defer {
        var it = hm.keyIterator();
        while (it.next()) |el| {
            allocator.free(el.*);
        }
    }

    var currents = std.ArrayList([]const u8).init(allocator);
    defer currents.deinit();
    var itk = hm.keyIterator();
    while (itk.next()) |el| {
        if (el.*[2] == 'A') {
            currents.append(el.*) catch unreachable;
        }
    }

    var results = std.ArrayList(u32).init(allocator);
    defer results.deinit();
    for (0..currents.items.len) |i| {
        var steps: u32 = 0;
        var current = hm.get(currents.items[i]).?;
        while (true) {
            var instruction = instructions[steps % instructions.len];
            var currentKey: []u8 = undefined;
            if (instruction == 'R') {
                currentKey = current.right;
                current = hm.get(current.right).?;
            } else {
                currentKey = current.left;
                current = hm.get(current.left).?;
            }
            steps += 1;
            if (currentKey[2] == 'Z') {
                results.append(steps) catch unreachable;
                break;
            }
        }
    }

    var res: u64 = results.items[0];
    for (1..results.items.len) |i| {
        res = lcm(res, results.items[i]);
    }

    std.debug.print("Result {d}\n", .{res});
}
