// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Lee Cannon <leecannon@leecannon.xyz>

//! Provides a kernel heap.
//!
//! Each allocation is a multiple of the standard page size.

pub fn allocate(len: usize) !core.VirtualRange {
    const allocation = try globals.heap_arena.allocate(
        len,
        .instant_fit,
    );

    return .{
        .address = .fromInt(allocation.base),
        .size = .from(allocation.len, .byte),
    };
}

pub fn deallocate(range: core.VirtualRange) void {
    globals.heap_arena.deallocate(.{
        .base = range.address.value,
        .len = range.size.value,
    });
}

pub const allocator = std.mem.Allocator{
    .ptr = undefined,
    .vtable = &.{
        .alloc = struct {
            fn alloc(
                _: *anyopaque,
                len: usize,
                _: u8,
                _: usize,
            ) ?[*]u8 {
                const allocation = globals.heap_arena.allocate(
                    len,
                    .instant_fit,
                ) catch return null;
                return @ptrFromInt(allocation.base);
            }
        }.alloc,
        .resize = struct {
            fn resize(
                _: *anyopaque,
                buf: []u8,
                _: u8,
                new_len: usize,
                _: usize,
            ) bool {
                std.debug.assert(new_len != 0);

                if (new_len <= buf.len) return true;
                if (new_len <= globals.heap_arena.quantum) return true;
                return false;
            }
        }.resize,
        .free = struct {
            fn free(
                _: *anyopaque,
                buf: []u8,
                _: u8,
                _: usize,
            ) void {
                globals.heap_arena.deallocateBase(@intFromPtr(buf.ptr));
            }
        }.free,
    },
};

pub fn _heapArenaImport(
    arena: *ResourceArena,
    len: usize,
    policy: ResourceArena.Policy,
) ResourceArena.AllocateError!ResourceArena.Allocation {
    const allocation = try arena.allocate(len, policy);

    log.debug("mapping {} into heap", .{allocation});

    kernel.mem.mapRange(
        &kernel.mem.globals.core_page_table,
        .{
            .address = .fromInt(allocation.base),
            .size = .from(allocation.len, .byte),
        },
        .{ .writeable = true, .global = true },
    ) catch return ResourceArena.AllocateError.RequestedLengthUnavailable;

    return allocation;
}

pub fn _heapArenaRelease(
    arena: *ResourceArena,
    allocation: ResourceArena.Allocation,
) void {
    log.debug("unmapping {} from heap", .{allocation});

    kernel.mem.unmapRange(
        &kernel.mem.globals.core_page_table,
        .{
            .address = .fromInt(allocation.base),
            .size = .from(allocation.len, .byte),
        },
        true,
    );

    arena.deallocate(allocation);
}

pub const globals = struct {
    /// An arena managing the heap's virtual address space.
    ///
    /// Has no source arena, provided with a single span representing the entire heap.
    ///
    /// Initialized during `init.initializeResourceArenasAndHeap`.
    pub var heap_address_space_arena: ResourceArena = undefined;

    /// The heap arena.
    ///
    /// Has a source arena of `heap_address_space_arena`. Backs imported spans with physical memory.
    ///
    /// Initialized during `init.initializeResourceArenasAndHeap`.
    pub var heap_arena: ResourceArena = undefined;
};

const core = @import("core");
const kernel = @import("kernel");
const std = @import("std");
const arch = @import("arch");
const ResourceArena = kernel.mem.ResourceArena;
const log = kernel.log.scoped(.heap);