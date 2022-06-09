const std = @import("std");
const print = std.debug.print;
const sleep = std.time.sleep;
const timestamp = std.time.milliTimestamp;
const tid = std.Thread.getCurrentId;
const linux = std.os.linux;
const net = std.net;

pub fn main() !void {
    try mainLoop();
}

var tick_count: u64 = 0;
var stop_count: u32 = 0;
var net_busy: bool = false;
var net_stop: bool = false;
const max_tick_count = 20;

fn waitForTick(epoll_fd: i32, id: i32, timeout_ms: u64) !void {
    printInfo(id, "ticker start", null);

    const timer_fd = try getFD(linux.timerfd_create(linux.CLOCK.MONOTONIC, 0), error.FailureTimerFdCreate);
    defer {
        _ = linux.close(timer_fd);
    }

    const time_interval = linux.timespec{
        .tv_sec = @intCast(isize, timeout_ms / std.time.ms_per_s),
        .tv_nsec = @intCast(isize, (timeout_ms % std.time.ms_per_s) * std.time.ns_per_ms),
    };

    const new_time = linux.itimerspec{
        .it_interval = time_interval,
        .it_value = time_interval,
    };

    if (linux.getErrno(linux.timerfd_settime(timer_fd, 0, &new_time, null)) != .SUCCESS)
        return error.FailureTimerFdSettime;

    var ev = linux.epoll_event{
        .events = linux.EPOLL.IN | linux.EPOLL.ET,
        .data = linux.epoll_data{ .ptr = @ptrToInt(@frame()) },
    };

    if (linux.getErrno(linux.epoll_ctl(epoll_fd, linux.EPOLL.CTL_ADD, timer_fd, &ev)) != .SUCCESS) {
        return error.FailureEpollCtlAdd;
    }
    defer {
        _ = linux.epoll_ctl(epoll_fd, linux.EPOLL.CTL_DEL, timer_fd, null);
    }

    while (tick_count < max_tick_count) {
        // wait for timer...
        suspend {}

        // timer is expired
        var exp_count: [@sizeOf(u64)]u8 = undefined;
        if (linux.getErrno(linux.read(timer_fd, &exp_count, exp_count.len)) != .SUCCESS) {
            return error.FailureTimerFdRead;
        }

        // increment tick count
        tick_count += 1;
        printInfo(id, "ticker fired", tick_count);
    }

    stop_count += 1;

    printInfo(id, "ticker stop", null);
}

fn waitForConnection(epoll_fd: i32, id: i32) !void {
    const localhost = try net.Address.parseIp("127.0.0.1", 15000);
    var server = net.StreamServer.init(.{
        .reuse_address = true,
        .kernel_backlog = 0,
    });
    defer server.deinit();

    try server.listen(localhost);

    printInfo(id, "listening on 127.0.0.1:15000", null);

    var ev = linux.epoll_event{
        .events = linux.EPOLL.IN | linux.EPOLL.ET,
        .data = linux.epoll_data{ .ptr = @ptrToInt(@frame()) },
    };

    if (linux.getErrno(linux.epoll_ctl(epoll_fd, linux.EPOLL.CTL_ADD, server.sockfd.?, &ev)) != .SUCCESS) {
        return error.FailureEpollCtlAdd;
    }
    defer {
        _ = linux.epoll_ctl(epoll_fd, linux.EPOLL.CTL_DEL, server.sockfd.?, null);
    }

    var conn_accepted: bool = false;
    var conn_frame: @Frame(acceptConnection) = undefined;

    while (true) {
        // wait for connection...
        suspend {}
        if (net_stop) {
            break;
        }

        if (net_busy) {
            var conn = try server.accept();
            conn.stream.close();
            continue;
        }

        if (conn_accepted) {
            try nosuspend await conn_frame;
        }

        conn_frame = async acceptConnection(epoll_fd, id, &server);
        conn_accepted = true;
    }

    if (conn_accepted) {
        try nosuspend await conn_frame;
    }

    printInfo(id, "listening stop", null);
}

fn acceptConnection(epoll_fd: i32, id: i32, server: *net.StreamServer) !void {
    net_busy = true;
    defer net_busy = false;

    var ev = linux.epoll_event{
        .events = linux.EPOLL.IN | linux.EPOLL.ET,
        .data = linux.epoll_data{ .ptr = @ptrToInt(@frame()) },
    };

    var conn = try server.accept();
    defer conn.stream.close();
    if (linux.getErrno(linux.epoll_ctl(epoll_fd, linux.EPOLL.CTL_ADD, conn.stream.handle, &ev)) != .SUCCESS) {
        return error.FailureEpollCtlAdd;
    }
    defer {
        _ = linux.epoll_ctl(epoll_fd, linux.EPOLL.CTL_DEL, conn.stream.handle, null);
    }

    // wait for data...
    suspend {}

    var buf: [1024]u8 = undefined;
    const nr = try conn.stream.reader().read(&buf);

    printInfo(id, buf[0..nr], nr);

    _ = try conn.stream.writer().write("thank you for chatting! :)\n");
}

fn mainLoop() !void {
    const epoll_fd = try getFD(linux.epoll_create1(linux.EPOLL.CLOEXEC), error.FailureEpoll);
    defer {
        _ = linux.close(epoll_fd);
    }

    const NTICKS = 2;
    var id: i32 = 1;
    var tick_frame: [NTICKS]@Frame(waitForTick) = undefined;
    while (id <= NTICKS) : (id += 1) {
        tick_frame[@intCast(usize, id - 1)] = async waitForTick(epoll_fd, id, 1000);
    }

    var server_frame = async waitForConnection(epoll_fd, id + 1);

    while (stop_count != NTICKS or net_busy) {
        var events: [NTICKS]linux.epoll_event = undefined;
        const rc = linux.epoll_wait(epoll_fd, events[0..], events.len, -1);
        const err = std.os.linux.getErrno(rc);
        if (err != .SUCCESS) {
            return error.FailedEpollWait;
        }
        for (events[0..rc]) |ev| {
            const frame = @intToPtr(anyframe, ev.data.ptr);
            resume frame;
        }
    }

    for (tick_frame) |*frame| {
        try nosuspend await frame;
    }

    net_stop = true;
    resume server_frame;
    try nosuspend await server_frame;
}

fn printInfo(id: i32, msg: []const u8, val: ?u64) void {
    print("[{d}][{d}][{d}] {s}", .{ timestamp(), tid(), id, msg });
    if (val) |value| {
        print(": {d}", .{value});
    }
    print("\n", .{});
}

fn getFD(rc: usize, err: anyerror) !i32 {
    if (linux.getErrno(rc) != .SUCCESS) {
        return err;
    }
    return @intCast(i32, rc);
}
