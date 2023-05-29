// SPDX-License-Identifier: MIT

const std = @import("std");
const core = @import("core");
const kernel = @import("kernel");
const x86_64 = @import("x86_64.zig");

pub const RFlags = packed struct(u64) {
    /// Set by hardware if last arithmetic operation generated a carry out of the most-significant bit of the result.
    carry: bool,

    _reserved1: u1,

    /// Set by hardware if last result has an even number of 1 bits (only for some operations).
    parity: bool,

    _reserved2: u1,

    /// Set by hardware if last arithmetic operation generated a carry out of bit 3 of the result.
    auxiliary_carry: bool,

    _reserved3: u1,

    /// Set by hardware if last arithmetic operation resulted in a zero value.
    zero: bool,

    /// Set by hardware if last arithmetic operation resulted in a negative value.
    sign: bool,

    /// Enable single-step mode for debugging.
    trap: bool,

    /// Enable interrupts.
    interrupt: bool,

    /// Determines the order in which strings are processed.
    direction: bool,

    /// Set by hardware to indicate that the sign bit of the result of the last signed integer
    /// operation differs from the source operands.
    overflow: bool,

    /// Specifies the privilege level required for executing I/O address-space instructions.
    iopl: u2,

    /// Used by `iret` in hardware task switch mode to determine if current task is nested.
    nested: bool,

    _reserved4: u1,

    /// Allows to restart an instruction following an instrucion breakpoint.
    @"resume": bool,

    /// Enable the virtual-8086 mode.
    virtual_8086: bool,

    /// Enable automatic alignment checking if CR0.AM is set. Only works if CPL is 3.
    alignment_check: bool,

    /// Virtual image of the INTERRUPT_FLAG bit.
    ///
    /// Used when virtual-8086 mode extensions (CR4.VME) or protected-mode virtual
    /// interrupts (CR4.PVI) are activated.
    virtual_interrupt: bool,

    /// Indicates that an external, maskable interrupt is pending.
    ///
    /// Used when virtual-8086 mode extensions (CR4.VME) or protected-mode virtual
    /// interrupts (CR4.PVI) are activated.
    virtual_interrupt_pending: bool,

    /// Processor feature identification flag.
    ///
    /// If this flag is modifiable, the CPU supports CPUID.
    id: bool,

    _reserved5: u42,

    /// Returns the current value of the RFLAGS register.
    pub inline fn read() RFlags {
        return @bitCast(RFlags, asm ("pushfq; popq %[ret]"
            : [ret] "=r" (-> u64),
        ));
    }

    /// Writes the RFLAGS register.
    /// Note: does not protect reserved bits, that is left up to the caller
    pub inline fn write(self: RFlags) void {
        asm volatile ("pushq %[val]; popfq"
            :
            : [val] "r" (@bitCast(u64, self)),
            : "flags"
        );
    }

    pub const format = core.formatStructIgnoreReserved;

    comptime {
        std.debug.assert(@bitSizeOf(u64) == @bitSizeOf(RFlags));
        std.debug.assert(@sizeOf(u64) == @sizeOf(RFlags));
    }
};

pub const Cr3 = struct {
    pub inline fn readAddress() kernel.PhysAddr {
        return kernel.PhysAddr.fromInt(asm ("mov %%cr3, %[value]"
            : [value] "=r" (-> u64),
        ) & 0xFFFF_FFFF_FFFF_F000);
    }

    pub inline fn writeAddress(addr: kernel.PhysAddr) void {
        asm volatile ("mov %[addr], %%cr3"
            :
            : [addr] "r" (addr.value & 0xFFFF_FFFF_FFFF_F000),
            : "memory"
        );
    }
};

/// Extended Feature Enable Register (EFER)
pub const EFER = packed struct(u64) {
    syscall_enable: bool,

    _reserved1_7: u7,

    long_mode_enable: bool,

    _reserved9: u1,

    long_mode_active: bool,

    no_execute_enable: bool,

    secure_virtual_machine_enable: bool,

    long_mode_segment_limit_enable: bool,

    fast_fxsave_fxrstor: bool,

    translation_cache_extension: bool,

    _reserved16: u1,

    mcommit_instruction_enable: bool,

    interruptible_wb_enable: bool,

    _reserved19: u1,

    upper_address_ingore_enable: bool,

    automatic_ibrs_enable: bool,

    _reserved22_63: u42,

    pub inline fn read() EFER {
        return @bitCast(EFER, msr.read());
    }

    pub inline fn write(self: EFER) void {
        msr.write(@bitCast(u64, self));
    }

    const msr = MSR(u64, 0xC0000080);

    pub const format = core.formatStructIgnoreReserved;
};

pub fn MSR(comptime T: type, comptime register: u32) type {
    return struct {
        pub inline fn read() T {
            switch (T) {
                u64 => {
                    var low: u32 = undefined;
                    var high: u32 = undefined;
                    asm volatile ("rdmsr"
                        : [low] "={eax}" (low),
                          [high] "={edx}" (high),
                        : [register] "{ecx}" (register),
                    );
                    return (@as(u64, high) << 32) | @as(u64, low);
                },
                u32 => {
                    return asm volatile ("rdmsr"
                        : [low] "={eax}" (-> u32),
                        : [register] "{ecx}" (register),
                        : "edx"
                    );
                },
                else => @compileError("read not implemented for " ++ @typeName(T)),
            }
        }

        pub inline fn write(value: T) void {
            switch (T) {
                u64 => {
                    asm volatile ("wrmsr"
                        :
                        : [reg] "{ecx}" (register),
                          [low] "{eax}" (@truncate(u32, value)),
                          [high] "{edx}" (@truncate(u32, value >> 32)),
                    );
                },
                u32 => {
                    asm volatile ("wrmsr"
                        :
                        : [reg] "{ecx}" (register),
                          [low] "{eax}" (value),
                          [high] "{edx}" (@as(u32, 0)),
                    );
                },
                else => @compileError("write not implemented for " ++ @typeName(T)),
            }
        }
    };
}
