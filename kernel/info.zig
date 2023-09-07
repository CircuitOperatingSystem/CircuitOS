// SPDX-License-Identifier: MIT

const std = @import("std");
const core = @import("core");
const kernel = @import("kernel");
const builtin = @import("builtin");
const target_options = @import("cascade_target");
const kernel_options = @import("kernel_options");

pub const mode: std.builtin.OptimizeMode = builtin.mode;
pub const arch = target_options.arch;
pub const version = kernel_options.cascade_version;
pub const root_path = kernel_options.root_path;

// This must be kept in sync with the linker scripts.
pub const kernel_base_address = kernel.VirtualAddress.fromInt(0xffffffff80000000);

pub var early_output_initialized: bool = false;

/// Set to true once all kernel setup code is complete.
pub var kernel_initialized: bool = false; // TODO: Set this to true once the setup code is complete.

/// Initialized during `setup`.
pub var kernel_virtual_base_address: kernel.VirtualAddress = undefined;

/// Initialized during `setup`.
pub var kernel_physical_base_address: kernel.PhysicalAddress = undefined;

/// Initialized during `setup`.
pub var kernel_virtual_slide: core.Size = undefined;

/// Initialized during `setup`.
pub var kernel_physical_to_virtual_offset: core.Size = undefined;

/// This direct map provides an identity mapping between virtual and physical addresses.
///
/// Initialized during `setup`.
pub var direct_map: kernel.VirtualRange = undefined;

/// This direct map provides an identity mapping between virtual and physical addresses.
///
/// The page tables used disable caching for this range.
///
/// Initialized during `setup`.
pub var non_cached_direct_map: kernel.VirtualRange = undefined;

/// This is the kernel's ELF file.
///
/// Initialized during `setup`.
pub var kernel_file: kernel.VirtualRange = undefined;

const log = kernel.log.scoped(.info);
