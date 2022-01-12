const std = @import("std");
const print = @import("std").debug.print;
const c = @import("c.zig");
const Clock = @import("Clock.zig");

pub fn main() anyerror!void {
    print("Starting clock server...\n", .{});

    var idb: c.CUuid = c.CUuid_createRandomUuid();
    var idw: c.CUuid = c.CUuid_createRandomUuid();

    var b: *c.CBroker = try c.CBroker_new(&idb, "clk_broker") orelse error.WorkerCreateError;
    var w: *c.CWorker = try c.CWorker_new(&idw, 0, "clk_worker") orelse error.BrokerCreateError;

    c.CWorker_addTopicsNames(w, "/clk/set");

    c.CBroker_start(b);
    c.CWorker_start(w);

    var clk = Clock{
        .tickMs = 1000,
        .tickCount = 0,
    };

    try clk.serveTicks(w);

    c.CWorker_stop(w);
    c.CWorker_wait(w);
    c.CWorker_delete(w);

    c.CBroker_stop(b);
    c.CBroker_wait(b);
    c.CBroker_delete(b);
}

pub fn createWorker(id: *c.CUuid) ?*c.CWorker {
    _ = id;
    return null;
}
