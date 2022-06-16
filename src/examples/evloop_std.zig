const std = @import("std");
const print = std.debug.print;
const sleep = std.time.sleep;
const timestamp = std.time.milliTimestamp;
const tid = std.Thread.getCurrentId;
const net = std.net;

pub const io_mode = .evented;
pub const event_loop_mode = .single_threaded;

const the_loop = std.event.Loop.instance orelse
    @compileError("event-based I/O loop is required");

pub fn main() !void {
    try mainLoop();
}

var tick_count: u64 = 0;
const max_tick_count = 20;

fn waitForTick(id: i32, timeout_ms: u64) !void {
    printInfo(id, "ticker start", null);

    while (tick_count < max_tick_count) {
        // wait for timer...
        sleep(timeout_ms * std.time.ns_per_ms);

        // increment tick count
        tick_count += 1;
        printInfo(id, "ticker fired", tick_count);
    }

    printInfo(id, "ticker stop", null);
}

fn acceptConnection(server: *net.StreamServer, id: i32) !void {
    const localhost = try net.Address.parseIp("127.0.0.1", 15000);
    try server.listen(localhost);

    printInfo(id, "listening on 127.0.0.1:15000", null);

    while (true) {
        var conn = server.accept() catch |err| switch (err) {
            error.SocketNotListening => return,
            else => return err,
        };
        defer conn.stream.close();

        var buf: [1024]u8 = undefined;
        const nr = try conn.stream.reader().read(&buf);

        printInfo(id, buf[0..nr], nr);

        _ = try conn.stream.writer().write("thank you for chatting! :)\n");
    }

    printInfo(id, "listening stop", null);
}

fn mainLoop() !void {
    printInfo(0, "mainLoop: start", null);

    const NTICKS = 2;
    var id: i32 = 1;
    var tick_frame: [NTICKS]@Frame(waitForTick) = undefined;
    while (id <= NTICKS) : (id += 1) {
        tick_frame[@intCast(usize, id - 1)] = async waitForTick(id, 500);
    }

    var server = net.StreamServer.init(.{
        .reuse_address = true,
        .kernel_backlog = 0,
    });
    defer server.deinit();

    var server_frame = async acceptConnection(&server, id + 1);

    for (tick_frame) |*frame| {
        try await frame;
    }

    try std.os.shutdown(server.sockfd.?, .recv);
    try await server_frame;

    printInfo(0, "mainLoop: end", null);
}

fn printInfo(id: i32, msg: []const u8, val: ?u64) void {
    print("[{d}][{d}][{d}] {s}", .{ timestamp(), tid(), id, msg });
    if (val) |value| {
        print(": {d}", .{value});
    }
    print("\n", .{});
}
