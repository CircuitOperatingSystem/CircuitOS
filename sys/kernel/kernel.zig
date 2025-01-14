// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Lee Cannon <leecannon@leecannon.xyz>

/// Array of all executors.
///
/// Initialized by `init.initializeExecutors` and never modified again.
pub var executors: []Executor = &.{};

/// Get the executor with the given id.
///
/// It is the caller's responsibility to ensure the executor exists.
pub inline fn getExecutor(id: Executor.Id) *Executor {
    return &executors[@intFromEnum(id)];
}

pub const acpi = @import("acpi.zig");
pub const config = @import("config.zig");
pub const debug = @import("debug.zig");
pub const entry = @import("entry.zig");
pub const Executor = @import("Executor.zig");
pub const log = @import("log.zig");
pub const mem = @import("mem/mem.zig");
pub const scheduler = @import("scheduler.zig");
pub const Stack = @import("Stack.zig");
pub const sync = @import("sync/sync.zig");
pub const Task = @import("Task.zig");
pub const time = @import("time.zig");

pub const init = @import("init.zig");

const std = @import("std");
const core = @import("core");
const arch = @import("arch");
