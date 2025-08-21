const std = @import("std");
const Connection = std.net.Server.Connection;


pub fn send200(conn: Connection) !void{
    const message = (
        "HTTP/1.1 200 OK\nContent-Length: 48"
        ++ "\nContent-Type: text/html\n"
        ++ "Connection: Closed\n\n<html><body>"
        ++ "<h1>Hello, World!</h1></body></html>"
    );

    _ = try conn.stream.write(message);

}

pub fn send404(conn: Connection) !void{
    const message = (
        "HTTP/1.1 404 OK\nContent-Length: 48"
        ++ "\nContent-Type: text/html\n"
        ++ "Connection: Closed\n\n<html><body>"
        ++ "<h1>File, not found!</h1></body></html>"
    );

    _ = try conn.stream.write(message);
}
