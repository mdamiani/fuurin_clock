const std = @import("std");
const print = std.debug.print;
const net = std.net;
const mem = std.mem;

pub const io_mode = .evented;

var conn_ended_cnt: u8 = 0;

pub fn main() !void {
    print("Starting server\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const leaked = gpa.deinit();
        if (leaked) {
            print("WARNING: leaked some memory\n", .{});
        }
    }

    var server = net.StreamServer.init(.{ .reuse_address = true });
    defer server.deinit();

    try server.listen(net.Address.parseIp("127.0.0.1", 58000) catch unreachable);
    print("listening at {}\n", .{server.listen_address});

    while (true) {
        print("waiting for accept...\n", .{});
        var conn = try server.accept();
        print("...accepted!\n", .{});

        if (conn_ended_cnt >= 3) {
            print("loop: max conn reached\n", .{});
            break;
        }

        var client = try allocator.create(Client);
        client.* = Client{
            .allocator = allocator,
            .conn = conn,
            .frame = async client.handle(),
        };

        print("loop: CONTINUE\n", .{});
    }

    server.close();

    print("loop: END\n", .{});
    return;
}

const Client = struct {
    allocator: mem.Allocator,
    conn: net.StreamServer.Connection,
    frame: @Frame(handle),

    pub fn handle(self: *Client) !void {
        print("handle: START\n", .{});
        _ = try self.conn.stream.write("welcome!\n");

        while (true) {
            var buf: [256]u8 = undefined;
            const n: usize = try self.conn.stream.read(&buf);
            if (n == 0) {
                self.conn.stream.close();
                break;
            }
            print("handle: recv: {s}\n", .{buf[0..n]});
            _ = try self.conn.stream.write(buf[0..n]);
        }

        suspend {
            // FIXME: increment should be atomic.
            conn_ended_cnt += 1;
            print("handle: DESTROY\n", .{});
            self.allocator.destroy(self);
            print("handle: END\n", .{});
        }
    }
};
