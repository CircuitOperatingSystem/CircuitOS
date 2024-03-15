// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Lee Cannon <leecannon@leecannon.xyz>

const std = @import("std");
const core = @import("core");
const kernel = @import("kernel");

const x86_64 = @import("x86_64.zig");

var idt: x86_64.Idt = .{};

pub const init = struct {
    /// Load the IDT on this cpu.
    pub fn loadIdt() void {
        idt.load();
    }
};
