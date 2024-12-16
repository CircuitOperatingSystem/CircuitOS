// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Lee Cannon <leecannon@leecannon.xyz>

//! Physical memory management.

pub const AllocatePageError = error{OutOfPhysicalMemory};

/// Allocates a physical page.
pub fn allocatePage() AllocatePageError!core.PhysicalRange {
    const free_page_node = globals.free_pages.pop() orelse {
        log.warn("PHYSCIAL PAGE ALLOCATION FAILED", .{});
        return error.OutOfPhysicalMemory;
    };
    errdefer comptime unreachable;

    _ = globals.free_memory.fetchSub(arch.paging.standard_page_size.value, .release);

    const virtual_range = core.VirtualRange.fromAddr(
        core.VirtualAddress.fromPtr(free_page_node),
        arch.paging.standard_page_size,
    );

    if (core.is_debug) {
        @memset(virtual_range.toByteSlice(), undefined);
    }

    const physical_range = kernel.mem.physicalRangeFromDirectMap(virtual_range) catch unreachable;

    log.debug("allocated: {}", .{physical_range});

    return physical_range;
}

/// Deallocates a physical page.
///
/// **REQUIREMENTS**:
/// - `range.address` must be aligned to `kernel.arch.paging.standard_page_size`
/// - `range.size` must be *equal* to `kernel.arch.paging.standard_page_size`
pub fn deallocatePage(range: core.PhysicalRange) void {
    std.debug.assert(range.address.isAligned(arch.paging.standard_page_size));
    std.debug.assert(range.size.equal(arch.paging.standard_page_size));

    const page_node = kernel.mem.directMapFromPhysical(range.address)
        .toPtr(*containers.SingleNode);
    globals.free_pages.push(page_node);

    _ = globals.free_memory.fetchAdd(arch.paging.standard_page_size.value, .release);

    log.debug("deallocated: {}", .{range});
}

pub const globals = struct {
    /// The list of free pages.
    ///
    /// Initialized during `init.initializePhysicalMemory`.
    pub var free_pages: containers.AtomicSinglyLinkedLIFO = .empty;

    /// The free physical memory.
    ///
    /// Updates to this value are eventually consistent.
    ///
    /// Initialized during `init.initializePhysicalMemory`.
    pub var free_memory: std.atomic.Value(u64) = undefined;

    /// The total physical memory.
    ///
    /// Does not change during the lifetime of the system.
    ///
    /// Initialized during `init.initializePhysicalMemory`.
    pub var total_memory: core.Size = undefined;

    /// The reserved physical memory.
    ///
    /// Does not change during the lifetime of the system.
    ///
    /// Initialized during `init.initializePhysicalMemory`.
    pub var reserved_memory: core.Size = undefined;

    /// The reclaimable physical memory.
    ///
    /// Will be reduced when the memory is reclaimed. // TODO: reclaim memory
    ///
    /// Initialized during `init.initializePhysicalMemory`.
    pub var reclaimable_memory: core.Size = undefined;

    /// The unavailable physical memory.
    ///
    /// Does not change during the lifetime of the system.
    ///
    /// Initialized during `init.initializePhysicalMemory`.
    pub var unavailable_memory: core.Size = undefined;
};

const core = @import("core");
const kernel = @import("kernel");
const std = @import("std");
const arch = @import("arch");
const containers = @import("containers");
const log = kernel.log.scoped(.mem_physical);
