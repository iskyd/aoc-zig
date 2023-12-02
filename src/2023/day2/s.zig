const std = @import("std");
const utils = @import("../../utils.zig");
const FileReader = utils.FileReader;
const DelimiterFileWrapIterator = utils.DelimiterFileWrapIterator;

const GameSet = struct {
    red: u16,
    green: u16,
    blue: u16,

    pub fn init(text: []const u8) GameSet {
        var it = std.mem.splitScalar(u8, text, ',');
        var red: u16 = 0;
        var green: u16 = 0;
        var blue: u16 = 0;
        while (it.next()) |s| {
            var it2 = std.mem.splitScalar(u8, std.mem.trim(u8, s, " "), ' ');
            const n = std.fmt.parseInt(u16, it2.next().?, 10) catch unreachable;
            const c = it2.next().?;
            if (std.mem.eql(u8, c, "red")) red = n;
            if (std.mem.eql(u8, c, "green")) green = n;
            if (std.mem.eql(u8, c, "blue")) blue = n;
        }
        return GameSet{ .red = red, .green = green, .blue = blue };
    }

    pub fn possible(self: GameSet) bool {
        if (self.red <= 12 and self.green <= 13 and self.blue <= 14) return true;
        return false;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    const filename = args[1];

    var fullpath = try allocator.alloc(u8, 14 + args[1].len);
    std.mem.copy(u8, fullpath[0..14], "src/2023/day2/");
    std.mem.copy(u8, fullpath[14..], filename);

    const reader = try FileReader.init(allocator, fullpath);
    defer reader.deinit();

    var iterator = DelimiterFileWrapIterator.init(reader.data, "\n");
    var sum: u16 = 0;
    var power: u32 = 0;
    while (iterator.next()) |line| {
        var it = std.mem.splitScalar(u8, line, ':');
        const gid = std.fmt.parseInt(u16, it.next().?[5..], 10) catch unreachable;
        var sit = std.mem.splitScalar(u8, it.next().?, ';');
        var possible: bool = true;
        var max_red: u16 = 0;
        var max_green: u16 = 0;
        var max_blue: u16 = 0;
        while (sit.next()) |s| {
            var gs: GameSet = GameSet.init(s);
            if (gs.possible() == false) {
                possible = false;
            }
            if (gs.red > max_red) max_red = gs.red;
            if (gs.green > max_green) max_green = gs.green;
            if (gs.blue > max_blue) max_blue = gs.blue;
        }
        if (possible) {
            sum += gid;
        }
        power += (max_red * max_green * max_blue);
    }

    std.debug.print("Result {d}\n", .{sum});
    std.debug.print("Result part 2 {d}\n", .{power});
}
