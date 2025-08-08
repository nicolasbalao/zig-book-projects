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

    const n_groups: usize = try std.math.divFloor(usize, input.len, 3);

    var result: usize = n_groups * 4;

    var i = 0;

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
    var memory_buffer: [1000]u8 = undefined;

    var fba = std.heap.FixedBufferAllocator.init(&memory_buffer);
    const allocator = fba.allocator();

    const output = try base64.encode(input, allocator);

    std.debug.print("Base 64 {s} : {s} \n\n", .{ input, output });

    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // Don't forget to flush!
}
