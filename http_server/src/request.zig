const std = @import("std");

pub const Connection = std.net.Server.Connection;

pub fn readRequest(conn: Connection, buffer: []u8) !void {
    _ = try conn.stream.read(buffer);
}

pub const Method = enum {
    GET,

    pub fn init(text: []const u8) !Method {
        return MethodMap.get(text).?;
    }

    pub fn is_supported(m: []const u8) bool {
        const method = MethodMap.get(m);

        if (method) {
            return true;
        }

        return false;
    }
};

const Map = std.static_string_map.StaticStringMap;

const MethodMap = Map(Method).initComptime(.{.{ "GET", Method.GET }});

pub const Request = struct {
    method: Method,
    uri: []const u8,
    version: []const u8,

    pub fn init(method: Method, uri: []const u8, version: []const u8) Request {
        return Request{ .method = method, .uri = uri, .version = version };
    }
};

pub fn parseRequest(text: []u8) Request {
    const line_index = std.mem.indexOfScalar(u8, text, '\n') orelse text.len;

    var iterator = std.mem.splitScalar(u8, text[0..line_index], ' ');

    const method = try Method.init(iterator.next().?);
    const uri = iterator.next().?;
    const version = iterator.next().?;

    return Request.init(method, uri, version);
}
