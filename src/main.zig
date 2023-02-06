const std = @import("std");
const print = @import("std").debug.print;
const os = std.os;
const c = @import("c.zig");

pub const io_mode = .evented;
pub const event_loop_mode = .single_threaded;
const the_loop = std.event.Loop.instance orelse
    @compileError("event-based I/O loop is required");

var tick_cnt: u64 = 0;

fn waitForTick(w: *c.CWorker, timeout_ms: u32) noreturn {
    while (true) {
        // wait for tick
        tick_cnt += 1;
        print("tick {d}\n", .{tick_cnt});
        dispatchInt(@TypeOf(tick_cnt), w, "/clock/tick", tick_cnt);
        std.time.sleep(timeout_ms * std.time.ns_per_ms);
    }
}

fn waitForTopic(w: *c.CWorker) !void {
    const evfd: os.fd_t = c.CWorker_eventFD(w);

    while (true) {
        the_loop.waitUntilFdReadable(evfd);
        read_loop: while (true) {
            var ev = c.CWorker_waitForEvent(w, 0) orelse return error.WaitForEvent;
            switch (c.CEvent_type(ev)) {
                c.EventInvalid => break :read_loop,
                c.EventStarted => print("ev started\n", .{}),
                c.EventStopped => print("ev stopped\n", .{}),
                c.EventOffline => print("ev offline\n", .{}),
                c.EventOnline => print("ev online\n", .{}),
                c.EventDelivery => {
                    const tick_num = try readInt(@TypeOf(tick_cnt), ev);
                    print("ev deliver: {d}\n", .{tick_num});
                },
                c.EventSyncRequest => print("ev syncreq\n", .{}),
                c.EventSyncBegin => print("ev syncbeg\n", .{}),
                c.EventSyncElement => print("ev syncelm\n", .{}),
                c.EventSyncSuccess => print("ev syncsuc\n", .{}),
                c.EventSyncError => print("ev syncerr\n", .{}),
                c.EventSyncDownloadOn => print("ev donwon\n", .{}),
                c.EventSyncDownloadOff => print("ev downoff\n", .{}),
                else => return error.UnknownEventType,
            }
        }
    }
}

fn dispatchInt(comptime T: type, w: *c.CWorker, name: []const u8, val: T) void {
    var buf: [@sizeOf(T)]u8 = undefined;
    std.mem.writeIntLittle(T, &buf, val);
    c.CWorker_dispatch(
        w,
        @ptrCast([*c]const u8, name),
        @ptrCast([*c]const u8, &buf),
        buf.len,
        c.TopicState,
    );
}

fn readInt(comptime T: type, ev: *c.CEvent) !T {
    var t = c.CEvent_topic(ev);
    if (c.CTopic_size(t) != @sizeOf(T)) {
        return error.UnexpectedTopicSize;
    }
    return std.mem.readIntLittle(T, @ptrCast(*const [@sizeOf(T)]u8, c.CTopic_data(t)));
}

pub fn main() !void {
    print("Starting clock server...\n", .{});

    var idb: c.CUuid = c.CUuid_createRandomUuid();
    var idw: c.CUuid = c.CUuid_createRandomUuid();

    var b: *c.CBroker = c.CBroker_new(&idb, "clk_broker") orelse return error.WorkerCreateError;
    var w: *c.CWorker = c.CWorker_new(&idw, 0, "clk_worker") orelse return error.BrokerCreateError;
    defer {
        c.CWorker_delete(w);
        c.CBroker_delete(b);
    }

    c.CWorker_addTopicsNames(w, "/clock/tick");

    c.CBroker_start(b);
    c.CWorker_start(w);
    if (!c.CWorker_waitForOnline(w, 5 * std.time.ms_per_s)) return error.WorkerStartError;
    defer {
        c.CWorker_stop(w);
        c.CWorker_wait(w);
        c.CBroker_stop(b);
        c.CBroker_wait(b);
    }

    _ = async waitForTick(w, 500);
    _ = async waitForTopic(w);

    the_loop.run();
}
