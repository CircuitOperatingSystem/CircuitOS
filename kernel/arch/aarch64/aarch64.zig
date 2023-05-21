// SPDX-License-Identifier: MIT

const std = @import("std");
const kernel = @import("root");

comptime {
    // make sure the entry points are referenced
    _ = @import("entry.zig");
}

/// Disable interrupts and put the CPU to sleep.
pub fn disableInterruptsAndHalt() noreturn {
    while (true) {
        asm volatile ("MSR DAIFSET, #0xF;");
    }
}

/// Logging function for early boot only.
pub fn earlyLogFn(
    comptime scope: @Type(.EnumLiteral),
    comptime message_level: kernel.log.Level,
    comptime format: []const u8,
    args: anytype,
) void {
    _ = args;
    _ = format;
    _ = message_level;
    _ = scope;
    @panic("UNIMPLEMENTED"); // TODO: implement earlyLogFn
}