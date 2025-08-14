//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
//!

const std = @import("std");

const Base64 = struct {
    _table: *const [64]u8,

    pub fn init() Base64 {
        const upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        const lower = "abcdefghijklmnopqrstuvwxyz";
        const numbers_symb = "0123456789+/";
        return Base64{
            ._table = upper ++ lower ++ numbers_symb,
        };
    }

    pub fn _char_at(self: Base64, index: usize) u8 {
        return self._table[index];
    }

    pub fn encode(self: Base64, input: []const u8, allocator: std.mem.Allocator) ![]u8 {
        if (input.len == 0) {
            return "";
        }

        const len_out = try calcEncodeLenght(input);
        var out = try allocator.alloc(u8, len_out);

        var buff = [3]u8{ 0, 0, 0 };
        var count: u8 = 0;
        var iout: u8 = 0;

        for (input, 0..) |_, i| {
            buff[count] = input[i];
            count += 1;

            if (count == 3) {
                out[iout] = self._char_at(buff[0] >> 2);
                out[iout + 1] = self._char_at(((buff[0] & 0x03) << 4) + (buff[1] >> 4));
                out[iout + 2] = self._char_at(((buff[1] & 0x0f) << 2) + (buff[2] >> 6));

                out[iout + 3] = self._char_at(buff[2] & 0x3f);

                iout += 4;
                count = 0;
            }
        }

        if (count == 1) {
            out[iout] = self._char_at(buff[0] >> 2);
            out[iout + 1] = self._char_at((buff[0] & 0x3) << 4);
            out[iout + 2] = '=';
            out[iout + 3] = '=';
        }

        if (count == 2) {
            out[iout] = self._char_at((buff[0] >> 2));
            out[iout + 1] = self._char_at(((buff[0] & 0x03) << 4) + (buff[1] >> 4));
            out[iout + 2] = self._char_at((buff[1] & 0x0f) << 2);
            out[iout + 3] = '=';

            iout += 4;
        }

        return out;
    }

    pub fn _char_index(self: Base64, char: u8) u8 {
        if (char == '=') {
            return 64;
        }

        var index: u8 = 0;

        for (0..63) |i| {
            if (self._char_at(i) == char) {
                break;
            }
            index += 1;
        }

        return index;
    }

    pub fn decode(self: Base64, input: []const u8, allocator: std.mem.Allocator) ![]u8 {
        if (input.len == 0) {
            return "";
        }

        const n_output = try calcDecodeLenght(input);
        var output = try allocator.alloc(u8, n_output);

        var count: u8 = 0;
        var iout: u64 = 0;
        var buff = [4]u8{ 0, 0, 0, 0 };

        for (0..input.len) |i| {
            buff[count] = self._char_index(input[i]);
            count += 1;

            if (count == 4) {
                output[iout] = (buff[0] << 2) + (buff[1] >> 4);
                if (buff[2] != 64) {
                    output[iout + 1] = (buff[1] << 4) + (buff[2] >> 2);
                }
                if (buff[3] != 64) {
                    output[iout + 2] = (buff[2] << 6) + buff[3];
                }
                iout += 3;
                count = 0;
            }
        }
        return output;
    }
};

fn calcEncodeLenght(input: []const u8) !usize {
    if (input.len < 3) {
        return 4;
    }

    const n_groups: usize = try std.math.divCeil(usize, input.len, 4);

    return n_groups * 4;
}

fn calcDecodeLenght(input: []const u8) !usize {
    if (input.len < 4) {
        return 3;
    }

    const n_groups: usize = try std.math.divFloor(usize, input.len, 4);

    var result: usize = n_groups * 3;

    var i: usize = input.len - 1;

    while (i > 0) : (i -= 1) {
        if (input[i] == '=') {
            result -= 1;
        } else {
            break;
        }
    }

    return result;
}

pub fn main() !void {
    const base64 = Base64.init();

    const input = "zig";
    const etext = "VGVzdGluZyBzb21lIG1vcmUgc3R1ZmY=";
    var memory_buffer: [1000]u8 = undefined;

    var fba = std.heap.FixedBufferAllocator.init(&memory_buffer);
    const allocator = fba.allocator();

    const encoded_output = try base64.encode(input, allocator);
    const decoded_ouput = try base64.decode(etext, allocator);

    std.debug.print("decoded: '{s}'\n", .{decoded_ouput});
    std.debug.print("len: {}, bytes: {any}\n", .{ decoded_ouput.len, decoded_ouput });

    std.debug.print("Base 64 encoded {s} : {s} \n\n", .{ input, encoded_output });
    std.debug.print("Base 64 decoded {s} : {s} \n\n", .{ etext, decoded_ouput });
}

test "should encode base64" {
    const base64 = Base64.init();

    const input = "zig";
    const expected = "emln";

    var memory_buffer: [1000]u8 = undefined;

    var fba = std.heap.FixedBufferAllocator.init(&memory_buffer);
    const allocator = fba.allocator();
    const encoded = try base64.encode(input, allocator);

    try std.testing.expectEqualStrings(expected, encoded);
}

test "should decode base64" {
    const base64 = Base64.init();

    const input = "VGVzdGluZyBzb21lIG1vcmUgc3R1ZmY=";
    const expected = "Testing some more stuff";

    var memory_buffer: [1000]u8 = undefined;

    var fba = std.heap.FixedBufferAllocator.init(&memory_buffer);
    const allocator = fba.allocator();
    const decoded = try base64.decode(input, allocator);

    try std.testing.expectEqualStrings(expected, decoded);
}
