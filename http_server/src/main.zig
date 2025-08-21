const std = @import("std");
const mySocket = @import("socket.zig");
const RequestHelper = @import("request.zig");
const Response = @import("response.zig");

// TODO:
// - find how to handle stdout with prin
// - How to print Ipv4 address
pub fn main() !void {
    const socket = try mySocket.Socket.init();
    defer socket._stream.close();

    std.debug.print("Server running on 127.0.0.1:3490\n", .{});

    var server = try socket._address.listen(.{});
    defer server.stream.close();

    const connection = try server.accept();
    defer connection.stream.close();
    var buffer: [1000]u8 = undefined;

    for (0..buffer.len) |i| {
        buffer[i] = 0;
    }

    try RequestHelper.readRequest(connection, buffer[0..buffer.len]);

    const request = RequestHelper.parseRequest(&buffer);

    if (request.method == RequestHelper.Method.GET) {
        if (std.mem.eql(u8, request.uri, "/")) {
            try Response.send200(connection);
        } else {
            try Response.send404(connection);
        }
    }
}
