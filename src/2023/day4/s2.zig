const std = @import("std");
const utils = @import("../../utils.zig");
const PriorityQueue = std.PriorityQueue;
const Order = std.math.Order;
const FileReader = utils.FileReader;
const DelimiterFileWrapIterator = utils.DelimiterFileWrapIterator;

const ScratchCard = struct { cn: u16, wn: std.ArrayList(u16), dn: std.ArrayList(u16) };

fn getWinnings(s: ScratchCard) u16 {
    var winnings: u16 = 0;
    for (s.wn.items) |n| {
        for (s.dn.items) |m| {
            if (n == m) {
                winnings += 1;
            }
        }
    }
    return winnings;
}

fn compareFn(context: void, a: ScratchCard, b: ScratchCard) Order {
    _ = context;
    if (a.cn < b.cn) {
        return Order.lt;
    } else {
        return Order.gt;
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    var q = PriorityQueue(ScratchCard, void, compareFn).init(allocator, {});
    defer q.deinit();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    const filename = args[1];

    var fullpath = try allocator.alloc(u8, 14 + args[1].len);
    defer allocator.free(fullpath);
    std.mem.copy(u8, fullpath[0..14], "src/2023/day4/");
    std.mem.copy(u8, fullpath[14..], filename);

    const reader = try FileReader.init(allocator, fullpath);
    defer reader.deinit();

    var hm = std.AutoHashMap(u16, ScratchCard).init(allocator);
    defer hm.deinit();

    var iterator = DelimiterFileWrapIterator.init(reader.data, "\n");
    while (iterator.next()) |line| {
        var it = std.mem.splitScalar(u8, line, ':');
        const game = it.next().?;
        const gn = std.fmt.parseInt(u16, std.mem.trim(u8, game[5..], " "), 10) catch unreachable;
        const numbers = it.next().?;
        var it2 = std.mem.splitScalar(u8, std.mem.trim(u8, numbers, " "), '|');
        var s1 = it2.next().?;
        var s2 = it2.next().?;
        var w = std.mem.splitScalar(u8, std.mem.trim(u8, s1, " "), ' ');
        var d = std.mem.splitScalar(u8, std.mem.trim(u8, s2, " "), ' ');
        var scratchCard = ScratchCard{ .cn = gn, .wn = std.ArrayList(u16).init(allocator), .dn = std.ArrayList(u16).init(allocator) };
        while (w.next()) |wn| {
            if (std.mem.eql(u8, std.mem.trim(u8, wn, " "), "")) {
                continue;
            }
            const n = std.fmt.parseInt(u16, std.mem.trim(u8, wn, " "), 10) catch unreachable;
            try scratchCard.wn.append(n);
        }
        while (d.next()) |dn| {
            if (std.mem.eql(u8, std.mem.trim(u8, dn, " "), "")) {
                continue;
            }
            const n = std.fmt.parseInt(u16, std.mem.trim(u8, dn, " "), 10) catch unreachable;
            try scratchCard.dn.append(n);
        }
        q.add(scratchCard) catch unreachable;
        hm.put(gn, scratchCard) catch unreachable;
    }

    defer {
        var it = hm.valueIterator();
        while (it.next()) |scratchcard| {
            scratchcard.wn.deinit();
            scratchcard.dn.deinit();
        }
    }

    var result: u32 = 0;
    while (q.removeOrNull()) |s| {
        // std.debug.print("Processing card number {d}\n", .{s.cn});
        const n = getWinnings(s);
        // std.debug.print("Find {d} winnings\n", .{n});
        if (n > 0) {
            for (s.cn + 1..s.cn + n + 1) |i| {
                // std.debug.print("Adding card number {d}\n", .{i});
                q.add(hm.get(@as(u16, @intCast(i))).?) catch unreachable;
            }
        }
        result += 1;
    }

    std.debug.print("Result = {d}\n", .{result});
}
