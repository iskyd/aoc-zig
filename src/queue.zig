const std = @import("std");

pub fn Queue(comptime K: type) type {
    return struct {
        const Self = @This();
        items: std.ArrayList(K),
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .items = std.ArrayList(K).init(allocator),
                .allocator = allocator,
            };
        }

        pub fn deinit(self: Self) void {
            self.items.deinit();
        }

        pub fn enqueue(self: *Self, item: K) !void {
            try self.items.append(item);
        }

        pub fn dequeue(self: *Self) ?K {
            if (self.items.items.len == 0) {
                return null;
            }
            var item = self.items.orderedRemove(0);
            return item;
        }
    };
}
