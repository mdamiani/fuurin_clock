const std = @import("std");

const c = @cImport({
    @cInclude("fuurin/c/cbroker.h");
    @cInclude("fuurin/c/cworker.h");
});

pub fn main() anyerror!void {
    std.log.info("Starting sim server...", .{});

    var idb: c.CUuid = c.CUuid_createRandomUuid();
    var idw: c.CUuid = c.CUuid_createRandomUuid();

    var b: *c.CBroker = c.CBroker_new(&idb, "srv_broker") orelse return;
    var w: *c.CWorker = c.CWorker_new(&idw, 0, "srv_worker") orelse return;

    c.CWorker_stop(w);
    c.CWorker_wait(w);
    c.CWorker_delete(w);

    c.CBroker_stop(b);
    c.CBroker_wait(b);
    c.CBroker_delete(b);
}
