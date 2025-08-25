const std = @import("std");
const stack_ds_lib = @import("stack_ds");
const Allocator = std.mem.Allocator;

// Stack u32 -> capacity, length, allocator, items init
//

const Stack = struct {
    items: []u32,
    capacity: u32,
    length: u32,
    allocator: Allocator,

    pub fn init(allocator: Allocator, capacity: u32) !Stack {
        var buf = try allocator.alloc(u32, capacity);
        return .{
            .items = buf[0..],
            .capacity = capacity,
            .length = 0,
            .allocator = allocator,
        };
    }

    pub fn push(self: *Stack, value: u32) !void {
        if (self.length + 1 > self.capacity) {
            var new_buf = try self.allocator.alloc(u32, self.capacity * 2);
            @memcpy(new_buf[0..self.capacity], self.items);

            self.allocator.free(self.items);
            self.items = new_buf;
            self.capacity = self.capacity * 2;
        }

        self.items[self.length] = value;
        self.length += 1;
    }

    pub fn pop(self: *Stack) !void {
        if (self.length == 0) {
            return;
        }

        self.items[self.length - 1] = undefined;
        self.length -= 1;
    }

    pub fn deinit(self: *Stack) void {
        self.allocator.free(self.items);
    }
};

pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
    try stack_ds_lib.bufferedPrint();
}

test "Stack.init should init" {
    const allocator = std.testing.allocator;

    var stack = try Stack.init(allocator, 32);
    defer stack.deinit();

    try std.testing.expectEqual(stack.length, 0);
    try std.testing.expectEqual(stack.capacity, 32);
}

test "Stack.push should push value" {
    const allocator = std.testing.allocator;

    var stack = try Stack.init(allocator, 32);
    defer stack.deinit();

    try stack.push(31);
    try stack.push(32);

    try std.testing.expectEqual(stack.items[0], 31);
    try std.testing.expectEqual(stack.items[1], 32);

    try std.testing.expectEqual(stack.length, 2);
    try std.testing.expectEqual(stack.capacity, 32);
}

test "Stack.push should double capacity when needed" {
    const allocator = std.testing.allocator;

    var stack = try Stack.init(allocator, 2);
    defer stack.deinit();

    try stack.push(31);
    try stack.push(32);
    try stack.push(33);

    try std.testing.expectEqual(stack.items[stack.length - 1], 33);
    try std.testing.expectEqual(stack.length, 3);
    try std.testing.expectEqual(stack.capacity, 4);
}

test "Stack.pop should pop last element" {
    const allocator = std.testing.allocator;

    var stack = try Stack.init(allocator, 32);
    defer stack.deinit();

    try stack.push(31);
    try stack.push(32);
    try stack.push(33);

    try std.testing.expectEqual(stack.items[stack.length - 1], 33);
    try std.testing.expectEqual(stack.length, 3);
    try std.testing.expectEqual(stack.capacity, 32);

    try stack.pop();

    try std.testing.expectEqual(stack.items[stack.length - 1], 32);
    try std.testing.expectEqual(stack.length, 2);
    try std.testing.expectEqual(stack.capacity, 32);
}
