const std = @import("std");
const c = @import("c.zig");

const Self = @This();

tickMs: u32,
tickCount: u64,

pub fn serveTicks(self: Self, worker: *c.CWorker) anyerror!void {
    _ = self;
    _ = worker;
    return error.TickError;
}
