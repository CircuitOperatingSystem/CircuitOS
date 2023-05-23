// SPDX-License-Identifier: MIT

const std = @import("std");
const kernel = @import("root");
const x86_64 = @import("x86_64.zig");

const limine = kernel.spec.limine;

/// Entry point.
export fn _start() callconv(.Naked) noreturn {
    @call(.never_inline, kernel.setup.setup, .{});
    @panic("setup returned");
}

var early_output_serial_port: x86_64.serial.SerialPort = undefined;

pub fn setupEarlyOutput() void {
    early_output_serial_port = x86_64.serial.SerialPort.init(.COM1, .Baud115200);
}

pub inline fn getEarlyOutputWriter() x86_64.serial.SerialPort.Writer {
    return early_output_serial_port.writer();
}