const std = @import("std");
const utils = @import("../../utils.zig");
const ascii = std.ascii;
const FileReader = utils.FileReader;
const DelimiterFileWrapIterator = utils.DelimiterFileWrapIterator;

const Hand = struct {
    bid: u32,
    cards: []u8,
};

fn convert(card: u8) u8 {
    switch (card) {
        'T' => return 10,
        'J' => return 11,
        'Q' => return 12,
        'K' => return 13,
        'A' => return 14,
        else => return card - '0',
    }
}

fn countOccurences(hand: []u8, search: u8) u8 {
    var count: u8 = 0;
    for (hand) |card| {
        if (card == search) {
            count += 1;
        }
    }
    return count;
}

fn isFive(hand: []u8) bool {
    return countOccurences(hand, hand[0]) == 5;
}

fn isFour(hand: []u8) bool {
    return countOccurences(hand, hand[0]) == 4 or countOccurences(hand, hand[1]) == 4;
}

fn isFull(hand: []u8) bool {
    return isThree(hand) and isPair(hand);
}

fn isThree(hand: []u8) bool {
    return countOccurences(hand, hand[0]) == 3 or countOccurences(hand, hand[1]) == 3 or countOccurences(hand, hand[2]) == 3;
}

fn isTwoPairs(hand: []u8) bool {
    var count: u8 = 0;
    for (hand) |card| {
        if (countOccurences(hand, card) == 2) {
            count += 1;
        }
    }
    return count == 4;
}

fn isPair(hand: []u8) bool {
    var count: u8 = 0;
    for (hand) |card| {
        if (countOccurences(hand, card) == 2) {
            count += 1;
        }
    }
    return count == 2;
}

fn handsPoint(hand: []u8) u8 {
    if (isFive(hand)) {
        return 7;
    } else if (isFour(hand)) {
        return 6;
    } else if (isFull(hand)) {
        return 5;
    } else if (isThree(hand)) {
        return 4;
    } else if (isTwoPairs(hand)) {
        return 3;
    } else if (isPair(hand)) {
        return 2;
    } else {
        return 1;
    }
}

fn lessThan(context: void, lhs: Hand, rhs: Hand) bool {
    _ = context;
    var p1: u8 = handsPoint(lhs.cards);
    var p2: u8 = handsPoint(rhs.cards);
    if (p1 != p2) {
        return p1 < p2;
    }
    for (0..5) |i| {
        if (convert(lhs.cards[i]) != convert(rhs.cards[i])) {
            return convert(lhs.cards[i]) < convert(rhs.cards[i]);
        }
    }
    unreachable;
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
    std.mem.copy(u8, fullpath[0..14], "src/2023/day7/");
    std.mem.copy(u8, fullpath[14..], filename);

    const reader = try FileReader.init(allocator, fullpath);
    defer reader.deinit();

    var iterator = DelimiterFileWrapIterator.init(reader.data, "\n");
    var hands = std.ArrayList(Hand).init(allocator);
    while (iterator.next()) |line| {
        var it = std.mem.split(u8, line, " ");
        var hand = it.next().?;
        var s = it.next().?;
        const copied = try allocator.dupe(u8, hand);
        var bid = std.fmt.parseInt(u32, s, 10) catch unreachable;
        hands.append(Hand{ .bid = bid, .cards = copied }) catch unreachable;
    }
    var slice = hands.toOwnedSlice() catch unreachable;
    defer allocator.free(slice);
    defer {
        for (slice) |hand| {
            allocator.free(hand.cards);
        }
    }
    var result: u32 = 0;
    std.mem.sort(Hand, slice, {}, lessThan);
    for (slice, 1..) |hand, i| {
        result += hand.bid * @as(u32, @intCast(i));
    }

    std.debug.print("Result: {d}\n", .{result});
}
