const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.build.Builder) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("master_clock", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);

    exe.linkSystemLibrary("c");
    exe.linkSystemLibrary("c++");

    exe.addIncludePath("src/fuurin/include/");
    exe.addIncludePath("src/fuurin/vendor/boost");
    exe.addIncludePath("src/fuurin/vendor/zeromq/include");

    const flags = [_][]const u8{
        "-Wall",
        "-Wextra",
        "-Werror=return-type",
        "-DLIB_VERSION_MAJOR=0",
        "-DLIB_VERSION_MINOR=0",
        "-DLIB_VERSION_PATCH=0",
        "-DBOOST_SCOPE_EXIT_CONFIG_USE_LAMBDAS",
        "-DZMQ_BUILD_DRAFT_API",
    };

    const cxxflags = flags ++ [_][]const u8{
        "-std=c++17",
    };

    const cxxsources = [_][]const u8{
        // fuurin
        "src/fuurin/src/arg.cpp",
        "src/fuurin/src/broker.cpp",
        "src/fuurin/src/brokerconfig.cpp",
        "src/fuurin/src/c/cbroker.cpp",
        "src/fuurin/src/c/cevent.cpp",
        "src/fuurin/src/c/ctopic.cpp",
        "src/fuurin/src/c/cutils.cpp",
        "src/fuurin/src/c/cuuid.cpp",
        "src/fuurin/src/c/cworker.cpp",
        "src/fuurin/src/connmachine.cpp",
        "src/fuurin/src/errors.cpp",
        "src/fuurin/src/event.cpp",
        "src/fuurin/src/failure.cpp",
        "src/fuurin/src/fuurin.cpp",
        "src/fuurin/src/log.cpp",
        "src/fuurin/src/logger.cpp",
        "src/fuurin/src/operation.cpp",
        "src/fuurin/src/runner.cpp",
        "src/fuurin/src/session.cpp",
        "src/fuurin/src/sessionbroker.cpp",
        "src/fuurin/src/sessionworker.cpp",
        "src/fuurin/src/syncmachine.cpp",
        "src/fuurin/src/topic.cpp",
        "src/fuurin/src/uuid.cpp",
        "src/fuurin/src/worker.cpp",
        "src/fuurin/src/workerconfig.cpp",
        "src/fuurin/src/zmqcancel.cpp",
        "src/fuurin/src/zmqcontext.cpp",
        "src/fuurin/src/zmqiotimer.cpp",
        "src/fuurin/src/zmqpart.cpp",
        "src/fuurin/src/zmqpollable.cpp",
        "src/fuurin/src/zmqpoller.cpp",
        "src/fuurin/src/zmqsocket.cpp",
        "src/fuurin/src/zmqtimer.cpp",

        // zeromq
        "src/fuurin/vendor/zeromq/src/address.cpp",
        "src/fuurin/vendor/zeromq/src/channel.cpp",
        "src/fuurin/vendor/zeromq/src/client.cpp",
        "src/fuurin/vendor/zeromq/src/clock.cpp",
        "src/fuurin/vendor/zeromq/src/ctx.cpp",
        "src/fuurin/vendor/zeromq/src/dealer.cpp",
        "src/fuurin/vendor/zeromq/src/decoder_allocators.cpp",
        "src/fuurin/vendor/zeromq/src/dgram.cpp",
        "src/fuurin/vendor/zeromq/src/dish.cpp",
        "src/fuurin/vendor/zeromq/src/dist.cpp",
        "src/fuurin/vendor/zeromq/src/endpoint.cpp",
        "src/fuurin/vendor/zeromq/src/err.cpp",
        "src/fuurin/vendor/zeromq/src/fq.cpp",
        "src/fuurin/vendor/zeromq/src/gather.cpp",
        "src/fuurin/vendor/zeromq/src/io_object.cpp",
        "src/fuurin/vendor/zeromq/src/io_thread.cpp",
        "src/fuurin/vendor/zeromq/src/ip.cpp",
        "src/fuurin/vendor/zeromq/src/ip_resolver.cpp",
        "src/fuurin/vendor/zeromq/src/ipc_address.cpp",
        "src/fuurin/vendor/zeromq/src/ipc_connecter.cpp",
        "src/fuurin/vendor/zeromq/src/ipc_listener.cpp",
        "src/fuurin/vendor/zeromq/src/lb.cpp",
        "src/fuurin/vendor/zeromq/src/mailbox.cpp",
        "src/fuurin/vendor/zeromq/src/mailbox_safe.cpp",
        "src/fuurin/vendor/zeromq/src/mechanism.cpp",
        "src/fuurin/vendor/zeromq/src/mechanism_base.cpp",
        "src/fuurin/vendor/zeromq/src/metadata.cpp",
        "src/fuurin/vendor/zeromq/src/msg.cpp",
        "src/fuurin/vendor/zeromq/src/mtrie.cpp",
        "src/fuurin/vendor/zeromq/src/null_mechanism.cpp",
        "src/fuurin/vendor/zeromq/src/object.cpp",
        "src/fuurin/vendor/zeromq/src/options.cpp",
        "src/fuurin/vendor/zeromq/src/own.cpp",
        "src/fuurin/vendor/zeromq/src/pair.cpp",
        "src/fuurin/vendor/zeromq/src/peer.cpp",
        "src/fuurin/vendor/zeromq/src/pipe.cpp",
        "src/fuurin/vendor/zeromq/src/plain_client.cpp",
        "src/fuurin/vendor/zeromq/src/plain_server.cpp",
        "src/fuurin/vendor/zeromq/src/poller_base.cpp",
        "src/fuurin/vendor/zeromq/src/polling_util.cpp",
        "src/fuurin/vendor/zeromq/src/proxy.cpp",
        "src/fuurin/vendor/zeromq/src/pub.cpp",
        "src/fuurin/vendor/zeromq/src/pull.cpp",
        "src/fuurin/vendor/zeromq/src/push.cpp",
        "src/fuurin/vendor/zeromq/src/radio.cpp",
        "src/fuurin/vendor/zeromq/src/radix_tree.cpp",
        "src/fuurin/vendor/zeromq/src/random.cpp",
        "src/fuurin/vendor/zeromq/src/raw_decoder.cpp",
        "src/fuurin/vendor/zeromq/src/raw_encoder.cpp",
        "src/fuurin/vendor/zeromq/src/raw_engine.cpp",
        "src/fuurin/vendor/zeromq/src/reaper.cpp",
        "src/fuurin/vendor/zeromq/src/rep.cpp",
        "src/fuurin/vendor/zeromq/src/req.cpp",
        "src/fuurin/vendor/zeromq/src/router.cpp",
        "src/fuurin/vendor/zeromq/src/scatter.cpp",
        "src/fuurin/vendor/zeromq/src/server.cpp",
        "src/fuurin/vendor/zeromq/src/session_base.cpp",
        "src/fuurin/vendor/zeromq/src/signaler.cpp",
        "src/fuurin/vendor/zeromq/src/socket_base.cpp",
        "src/fuurin/vendor/zeromq/src/socket_poller.cpp",
        "src/fuurin/vendor/zeromq/src/socks.cpp",
        "src/fuurin/vendor/zeromq/src/socks_connecter.cpp",
        "src/fuurin/vendor/zeromq/src/stream.cpp",
        "src/fuurin/vendor/zeromq/src/stream_connecter_base.cpp",
        "src/fuurin/vendor/zeromq/src/stream_engine_base.cpp",
        "src/fuurin/vendor/zeromq/src/stream_listener_base.cpp",
        "src/fuurin/vendor/zeromq/src/sub.cpp",
        "src/fuurin/vendor/zeromq/src/tcp.cpp",
        "src/fuurin/vendor/zeromq/src/tcp_address.cpp",
        "src/fuurin/vendor/zeromq/src/tcp_connecter.cpp",
        "src/fuurin/vendor/zeromq/src/tcp_listener.cpp",
        "src/fuurin/vendor/zeromq/src/thread.cpp",
        "src/fuurin/vendor/zeromq/src/timers.cpp",
        "src/fuurin/vendor/zeromq/src/udp_address.cpp",
        "src/fuurin/vendor/zeromq/src/udp_engine.cpp",
        "src/fuurin/vendor/zeromq/src/v1_decoder.cpp",
        "src/fuurin/vendor/zeromq/src/v1_encoder.cpp",
        "src/fuurin/vendor/zeromq/src/v2_decoder.cpp",
        "src/fuurin/vendor/zeromq/src/v2_encoder.cpp",
        "src/fuurin/vendor/zeromq/src/v3_1_encoder.cpp",
        "src/fuurin/vendor/zeromq/src/ws_address.cpp",
        "src/fuurin/vendor/zeromq/src/ws_connecter.cpp",
        "src/fuurin/vendor/zeromq/src/ws_decoder.cpp",
        "src/fuurin/vendor/zeromq/src/ws_encoder.cpp",
        "src/fuurin/vendor/zeromq/src/ws_engine.cpp",
        "src/fuurin/vendor/zeromq/src/ws_listener.cpp",
        "src/fuurin/vendor/zeromq/src/xpub.cpp",
        "src/fuurin/vendor/zeromq/src/xsub.cpp",
        "src/fuurin/vendor/zeromq/src/zap_client.cpp",
        "src/fuurin/vendor/zeromq/src/zmq.cpp",
        "src/fuurin/vendor/zeromq/src/zmq_utils.cpp",
        "src/fuurin/vendor/zeromq/src/zmtp_engine.cpp",
    };

    for (cxxsources) |file| {
        exe.addCSourceFile(file, &cxxflags);
    }

    exe.addCSourceFile("src/fuurin/vendor/zeromq/external/sha1/sha1.c", &flags);

    if (builtin.os.tag == .macos) {
        exe.addIncludePath("src/fuurin/vendor/zeromq/src/platform/macos");
        exe.addCSourceFile("src/fuurin/vendor/zeromq/src/kqueue.cpp", &cxxflags);
    }

    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
