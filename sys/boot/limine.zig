// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Lee Cannon <leecannon@leecannon.xyz>

pub fn exportRequests() void {
    @export(&requests.limine_base_revison, .{ .name = "limine_base_revison_request" });
    @export(&requests.entry_point, .{ .name = "limine_entry_point_request" });
    @export(&requests.kernel_address, .{ .name = "limine_kernel_address_request" });
    @export(&requests.hhdm, .{ .name = "limine_hhdm_request" });
    @export(&requests.memmap, .{ .name = "limine_memmap_request" });
    @export(&requests.rsdp, .{ .name = "limine_rsdp_request" });
    @export(&requests.smp, .{ .name = "limine_smp_request" });
}

pub fn kernelBaseAddress() ?boot.KernelBaseAddress {
    const resp = requests.kernel_address.response orelse
        return null;

    return .{
        .virtual = resp.virtual_base,
        .physical = resp.physical_base,
    };
}

pub fn directMapAddress() ?core.VirtualAddress {
    const resp = requests.hhdm.response orelse
        return null;

    return resp.offset;
}

pub fn rsdp() ?core.Address {
    const resp = requests.rsdp.response orelse
        return null;

    return resp.address(limine_revison);
}

pub fn x2apicEnabled() bool {
    std.debug.assert(@import("cascade_target").arch == .x64);

    const resp: *const limine.SMP.x86_64 = requests.smp.response orelse
        return false;

    return resp.flags.x2apic_enabled;
}

pub fn memoryMap(direction: core.Direction) ?boot.MemoryMap {
    const resp = requests.memmap.response orelse
        return null;

    var result: boot.MemoryMap = .{
        .backing = undefined,
    };

    const limine_memory_map = std.mem.bytesAsValue(MemoryMapIterator, &result.backing);

    const entries = resp.entries();

    limine_memory_map.* = .{
        .index = switch (direction) {
            .forward => 0,
            .backward => entries.len,
        },
        .entries = entries,
        .direction = direction,
    };

    return result;
}

pub const MemoryMapIterator = struct {
    index: usize,
    entries: []const *const limine.Memmap.Entry,
    direction: core.Direction,

    pub fn next(memory_map: *boot.MemoryMap) ?boot.MemoryMap.Entry {
        const self: *MemoryMapIterator = @ptrCast(@alignCast(&memory_map.backing));

        const limine_entry = switch (self.direction) {
            .backward => blk: {
                if (self.index == 0) return null;
                self.index -= 1;
                break :blk self.entries[self.index];
            },
            .forward => blk: {
                if (self.index >= self.entries.len) return null;
                const entry = self.entries[self.index];
                self.index += 1;
                break :blk entry;
            },
        };

        return .{
            .range = .fromAddr(limine_entry.base, limine_entry.length),
            .type = switch (limine_entry.type) {
                .usable => .free,
                .kernel_and_modules, .framebuffer => .in_use,
                .reserved, .acpi_nvs => .reserved,
                .bootloader_reclaimable => .bootloader_reclaimable,
                .acpi_reclaimable => .acpi_reclaimable,
                .bad_memory => .unusable,
                else => .unknown,
            },
        };
    }
};

pub fn cpuDescriptors() ?boot.CpuDescriptors {
    const resp = requests.smp.response orelse
        return null;

    var result: boot.CpuDescriptors = .{
        .backing = undefined,
    };

    const descriptor_iterator = std.mem.bytesAsValue(CpuDescriptorIterator, &result.backing);

    descriptor_iterator.* = .{
        .index = 0,
        .entries = resp.cpus(),
    };

    return result;
}

pub const CpuDescriptorIterator = struct {
    index: usize,
    entries: []*limine.SMP.Response.SMPInfo,

    pub const Descriptor = struct {
        smp_info: *limine.SMP.Response.SMPInfo,
    };

    pub fn count(cpu_descriptors: *const boot.CpuDescriptors) usize {
        const descriptor_iterator = std.mem.bytesAsValue(CpuDescriptorIterator, &cpu_descriptors.backing);
        return descriptor_iterator.entries.len;
    }

    pub fn next(cpu_descriptors: *boot.CpuDescriptors) ?boot.CpuDescriptors.Descriptor {
        const descriptor_iterator = std.mem.bytesAsValue(CpuDescriptorIterator, &cpu_descriptors.backing);

        if (descriptor_iterator.index >= descriptor_iterator.entries.len) return null;

        const smp_info = descriptor_iterator.entries[descriptor_iterator.index];

        descriptor_iterator.index += 1;

        var result: boot.CpuDescriptors.Descriptor = .{
            .backing = undefined,
        };

        const descriptor = std.mem.bytesAsValue(Descriptor, &result.backing);

        descriptor.* = .{ .smp_info = smp_info };

        return result;
    }

    pub fn bootFn(
        generic_descriptor: *const boot.CpuDescriptors.Descriptor,
        user_data: *anyopaque,
        comptime targetFn: fn (user_data: *anyopaque) noreturn,
    ) void {
        const trampolineFn = struct {
            fn trampolineFn(smp_info: *const limine.SMP.Response.SMPInfo) callconv(.C) noreturn {
                targetFn(@ptrFromInt(smp_info.extra_argument));
            }
        }.trampolineFn;

        const descriptor = std.mem.bytesAsValue(Descriptor, &generic_descriptor.backing);
        const smp_info = descriptor.smp_info;

        @atomicStore(
            usize,
            &smp_info.extra_argument,
            @intFromPtr(user_data),
            .release,
        );

        @atomicStore(
            ?*const fn (*const limine.SMP.Response.SMPInfo) callconv(.C) noreturn,
            &smp_info.goto_address,
            &trampolineFn,
            .release,
        );
    }

    pub fn processorId(
        generic_descriptor: *const boot.CpuDescriptors.Descriptor,
    ) u32 {
        const descriptor = std.mem.bytesAsValue(Descriptor, &generic_descriptor.backing);
        return descriptor.smp_info.processor_id;
    }
};

fn limineEntryPoint() callconv(.C) noreturn {
    boot.bootloader_api = .limine;

    if (requests.limine_base_revison.revison == .@"0") {
        // limine sets the `revison` field to `0` to signal that the requested revision is supported
        limine_revison = target_limine_revison;
    }

    @call(.never_inline, @import("root").initEntryPoint, .{}) catch |err| {
        core.panicFmt("unhandled error: {s}", .{@errorName(err)}, @errorReturnTrace());
    };
    core.panic("`initEntryPoint` returned", null);
}

// TODO: update to 3, needs annoying changes as things like the ACPI RSDP are not mapped in the
//       HHDM from that revision onwards
const target_limine_revison: limine.BaseRevison.Revison = .@"2";
var limine_revison: limine.BaseRevison.Revison = .@"0";

const requests = struct {
    var limine_base_revison: limine.BaseRevison = .{ .revison = target_limine_revison };
    var entry_point: limine.EntryPoint = .{ .entry = limineEntryPoint };
    var kernel_address: limine.KernelAddress = .{};
    var hhdm: limine.HHDM = .{};
    var memmap: limine.Memmap = .{};
    var rsdp: limine.RSDP = .{};
    var smp: limine.SMP = .{ .flags = .{ .x2apic = true } };
};

const std = @import("std");
const core = @import("core");
const limine = @import("limine");
const boot = @import("boot");
