const std = @import("std");
const math = std.math;
const utils = @import("../../utils.zig");
const Queue = @import("../../queue.zig").Queue;
const ascii = std.ascii;
const FileReader = utils.FileReader;
const DelimiterFileWrapIterator = utils.DelimiterFileWrapIterator;

const Point = struct {
    x: usize,
    y: usize,
};

fn contains(p: Point, points: []Point) bool {
    for (points) |point| {
        if (point.x == p.x and point.y == p.y) {
            return true;
        }
    }
    return false;
}

fn inside(p: Point, map: std.ArrayList(std.ArrayList(u8))) bool {
    return p.x < map.items.len and p.y < map.items[0].items.len and p.x >= 0 and p.y >= 0;
}

fn getNeighbours(map: std.ArrayList(std.ArrayList(u8)), p: Point, s1: *?Point, s2: *?Point) void {
    const pipe = map.items[p.x].items[p.y];
    switch (pipe) {
        '|' => {
            if (p.x > 0) {
                s1.* = Point{ .x = p.x - 1, .y = p.y };
            }
            s2.* = Point{ .x = p.x + 1, .y = p.y };
        },
        '-' => {
            if (p.y > 0) {
                s1.* = Point{ .x = p.x, .y = p.y - 1 };
            }
            s2.* = Point{ .x = p.x, .y = p.y + 1 };
        },
        'L' => {
            if (p.x > 0) {
                s1.* = Point{ .x = p.x - 1, .y = p.y };
            }
            s2.* = Point{ .x = p.x, .y = p.y + 1 };
        },
        'J' => {
            if (p.y > 0) {
                s1.* = Point{ .x = p.x, .y = p.y - 1 };
            }
            if (p.x > 0) {
                s2.* = Point{ .x = p.x - 1, .y = p.y };
            }
        },
        '7' => {
            if (p.y > 0) {
                s1.* = Point{ .x = p.x, .y = p.y - 1 };
            }
            s2.* = Point{ .x = p.x + 1, .y = p.y };
        },
        'F' => {
            s1.* = Point{ .x = p.x + 1, .y = p.y };
            s2.* = Point{ .x = p.x, .y = p.y + 1 };
        },
        else => {},
    }
}

fn getNeighbour(map: std.ArrayList(std.ArrayList(u8)), p: Point, visited: std.ArrayList(Point)) ?Point {
    var p1: ?Point = null;
    var p2: ?Point = null;
    getNeighbours(map, p, &p1, &p2);
    if (p1 != null and inside(p1.?, map) == true and contains(p1.?, visited.items) == false) {
        return p1;
    }
    if (p2 != null and inside(p2.?, map) == true and contains(p2.?, visited.items) == false) {
        return p2;
    }
    return null;
}

// Returns the points
fn follow(allocator: std.mem.Allocator, map: std.ArrayList(std.ArrayList(u8)), s: Point) ?[]Point {
    var visited = std.ArrayList(Point).init(allocator);
    defer visited.deinit();
    var s1 = getNeighbour(map, s, visited);
    if (s1 == null) {
        return null;
    }
    visited.append(s1.?) catch unreachable;
    var s2 = getNeighbour(map, s, visited);
    if (s2 == null) {
        return null;
    }
    visited.append(s2.?) catch unreachable;
    visited.append(s) catch unreachable;

    var i: usize = 1;
    while (true) : (i += 1) {
        if (map.items[s1.?.x].items[s1.?.y] == '.' or map.items[s2.?.x].items[s2.?.y] == '.') {
            break;
        }
        if (s1.?.x == s2.?.x and s1.?.y == s2.?.y) {
            var slice = allocator.alloc(Point, i * 2 + 1) catch unreachable;
            for (visited.items, 0..) |p, j| {
                slice[j] = p;
            }
            return slice;
        }
        s1 = getNeighbour(map, s1.?, visited);
        s2 = getNeighbour(map, s2.?, visited);

        if (s1 == null or s2 == null) {
            break;
        }
        visited.append(s1.?) catch unreachable;
        visited.append(s2.?) catch unreachable;
    }

    return null;
}

fn isinside(map: std.ArrayList(std.ArrayList(u8)), points: []Point, x: usize, y: usize) bool {
    // Raycasting algorithm
    const line = map.items[x];
    var count: usize = 0;
    for (0..y) |i| {
        if (contains(Point{ .x = x, .y = i }, points) == false) {
            continue;
        }
        if (line.items[i] == 'J' or line.items[i] == 'L' or line.items[i] == '|') {
            count += 1;
        }
    }
    if (count % 2 == 1) {
        return true;
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

    var fullpath = try allocator.alloc(u8, 15 + args[1].len);
    defer allocator.free(fullpath);
    std.mem.copy(u8, fullpath[0..15], "src/2023/day10/");
    std.mem.copy(u8, fullpath[15..], filename);

    const reader = try FileReader.init(allocator, fullpath);
    defer reader.deinit();

    var iterator = DelimiterFileWrapIterator.init(reader.data, "\n");

    var map = std.ArrayList(std.ArrayList(u8)).init(allocator);
    defer map.deinit();
    var s: Point = undefined;
    var i: usize = 0;
    while (iterator.next()) |line| : (i += 1) {
        var row = std.ArrayList(u8).init(allocator);
        for (0..line.len) |j| {
            if (line[j] == 'S') {
                s = Point{ .x = i, .y = j };
            }
            row.append(line[j]) catch unreachable;
        }
        map.append(row) catch unreachable;
    }
    defer {
        for (map.items) |row| {
            row.deinit();
        }
    }

    const pipes = [_]u8{ '|', '.', 'L', 'J', '7', 'F' };
    var points: []Point = allocator.alloc(Point, 0) catch unreachable;
    for (pipes) |pipe| {
        map.items[s.x].items[s.y] = pipe;
        var res = follow(allocator, map, s);
        if (res != null) {
            defer allocator.free(res.?);
            if (res.?.len > points.len) {
                allocator.free(points);
                points = allocator.alloc(Point, res.?.len) catch unreachable;
                for (res.?, 0..) |p, j| {
                    points[j] = p;
                }
            }
        }
    }
    defer allocator.free(points);

    var res: usize = 0;
    for (0..map.items.len) |l| {
        for (0..map.items[0].items.len) |m| {
            if (contains(Point{ .x = l, .y = m }, points) == false) {
                if (isinside(map, points, l, m)) {
                    res += 1;
                }
            }
        }
    }

    std.debug.print("Result: {d}\n", .{res});
}
