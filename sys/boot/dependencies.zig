// SPDX-License-Identifier: CC0-1.0
// SPDX-FileCopyrightText: 2024 Lee Cannon <leecannon@leecannon.xyz>

pub const dependencies: []const LibraryDependency = &[_]LibraryDependency{
    .{ .name = "core" },
    .{ .name = "limine" },
};

const LibraryDependency = @import("../../build/LibraryDependency.zig");
