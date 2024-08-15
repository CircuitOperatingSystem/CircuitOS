// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Lee Cannon <leecannon@leecannon.xyz>

/// Entry point from the Zig language upon a panic.
pub fn zigPanic(
    msg: []const u8,
    stack_trace: ?*const std.builtin.StackTrace,
    return_address_opt: ?usize,
) noreturn {
    @branchHint(.cold);

    kernel.arch.interrupts.disableInterrupts();

    panic_impl(
        msg,
        stack_trace,
        return_address_opt orelse @returnAddress(),
    );

    while (true) {
        kernel.arch.interrupts.disableInterruptsAndHalt();
    }
}

var panic_impl: *const fn (
    msg: []const u8,
    stack_trace: ?*const std.builtin.StackTrace,
    return_address: usize,
) void = struct {
    fn noOpPanic(
        msg: []const u8,
        stack_trace: ?*const std.builtin.StackTrace,
        return_address: usize,
    ) void {
        _ = msg;
        _ = stack_trace;
        _ = return_address;
    }
}.noOpPanic;

const std = @import("std");
const core = @import("core");
const kernel = @import("kernel");
