// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Lee Cannon <leecannon@leecannon.xyz>

//! Represents a single execution resource.

const std = @import("std");
const core = @import("core");
const kernel = @import("kernel");

const Cpu = @This();

id: Id,

/// Tracks the number of times we have disabled interrupts.
///
/// This allows support for nested disables.
interrupt_disable_count: u32,

/// Tracks the number of times we have disabled preemption.
///
/// This allows support for nested disables.
preemption_disable_count: u32,

/// Tracks the number of times we have not scheduled due to preemption being disabled.
schedules_skipped: u32 = 0,

/// The stack used for idle.
///
/// Also used during the move from the bootloader provided stack until we start scheduling.
idle_stack: kernel.Stack,

/// The currently running thread.
///
/// This is set to `null` when the processor is idle and also before we start scheduling.
current_thread: ?*kernel.Thread = null,

arch: kernel.arch.ArchCpu,

pub const Id = enum(u32) {
    none = std.math.maxInt(u32),

    _,
};