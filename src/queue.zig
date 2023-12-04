const std = @import("std");

pub fn Queue(comptime K: type) type {
    return struct {
        items: std.ArrayList(K),
        allocator: std.mem.Allocator,

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .items = std.ArrayList(K).init(allocator),
                .allocator = allocator,
            };
        }

        pub fn deinit(self: Self) void {
            self.allocator.free(self.items);
            self.items = undefined;
        }
    };
}
