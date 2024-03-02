// SPDX-License-Identifier: CC0-1.0
// SPDX-FileCopyrightText: 2024 Lee Cannon <leecannon@leecannon.xyz>

const LibraryDescription = @import("../build/LibraryDescription.zig");

pub const libraries: []const LibraryDescription = &[_]LibraryDescription{
    .{ .name = "acpi", .dependencies = &.{"core"} },
    .{ .name = "bitjuggle" },
    .{ .name = "containers", .dependencies = &.{ "core", "bitjuggle" } },
    .{ .name = "core" },
    .{ .name = "fs", .dependencies = &.{ "core", "uuid" } },
    .{ .name = "limine", .dependencies = &.{"core"} },
    .{ .name = "sdf" },
    .{ .name = "uuid", .dependencies = &.{"core"} },
    .{
        .name = "x86_64",
        .dependencies = &.{ "core", "bitjuggle" },
        .supported_targets = &.{.x86_64},
    },
};
