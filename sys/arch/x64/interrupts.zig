// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Lee Cannon <leecannon@leecannon.xyz>

pub const disableInterruptsAndHalt = lib_x64.instructions.disableInterruptsAndHalt;
pub const disableInterrupts = lib_x64.instructions.disableInterrupts;
pub const enableInterrupts = lib_x64.instructions.enableInterrupts;
pub const areEnabled = lib_x64.instructions.interruptsEnabled;

pub const InterruptContext = *InterruptFrame;

pub const InterruptStackSelector = enum(u3) {
    double_fault,
    non_maskable_interrupt,
};

pub const Interrupt = enum(u8) {
    divide = 0,
    debug = 1,
    non_maskable_interrupt = 2,
    breakpoint = 3,
    overflow = 4,
    bound_range = 5,
    invalid_opcode = 6,
    device_not_available = 7,
    double_fault = 8,
    coprocessor_segment_overrun = 9,
    invalid_tss = 10,
    segment_not_present = 11,
    stack_fault = 12,
    general_protection = 13,
    page_fault = 14,
    _reserved1 = 15,
    x87_floating_point = 16,
    alignment_check = 17,
    machine_check = 18,
    simd_floating_point = 19,
    virtualization = 20,
    control_protection = 21,
    _reserved2 = 22,
    _reserved3 = 23,
    _reserved4 = 24,
    _reserved5 = 25,
    _reserved6 = 26,
    _reserved7 = 27,
    hypervisor_injection = 28,
    vmm_communication = 29,
    security = 30,
    _reserved8 = 31,

    pic_pit = 32,
    pic_keyboard = 33,
    pic_cascade = 34,
    pic_com2 = 35,
    pic_com1 = 36,
    pic_lpt2 = 37,
    pic_floppy = 38,
    pic_lpt1 = 39,
    pic_rtc = 40,
    pic_free1 = 41,
    pic_free2 = 42,
    pic_free3 = 43,
    pic_ps2mouse = 44,
    pic_fpu = 45,
    pic_primary_ata = 46,
    pic_secondary_ata = 47,

    per_executor_periodic = 48,

    spurious_interrupt = 255,

    _,

    pub inline fn toInterruptVector(self: Interrupt) lib_x64.InterruptVector {
        return @enumFromInt(@intFromEnum(self));
    }

    pub inline fn hasErrorCode(self: Interrupt) bool {
        return self.toInterruptVector().hasErrorCode();
    }

    pub inline fn isException(self: Interrupt) bool {
        return self.toInterruptVector().isException();
    }
};

pub const InterruptFrame = extern struct {
    interrupt_disable_count: u32,
    es: extern union {
        full: u64,
        selector: Gdt.Selector,
    },
    ds: extern union {
        full: u64,
        selector: Gdt.Selector,
    },
    r15: u64,
    r14: u64,
    r13: u64,
    r12: u64,
    r11: u64,
    r10: u64,
    r9: u64,
    r8: u64,
    rdi: u64,
    rsi: u64,
    rbp: u64,
    rdx: u64,
    rcx: u64,
    rbx: u64,
    rax: u64,
    vector_number: extern union {
        full: u64,
        interrupt: Interrupt,
    },
    error_code: u64,
    rip: u64,
    cs: extern union {
        full: u64,
        selector: Gdt.Selector,
    },
    rflags: lib_x64.registers.RFlags,
    rsp: u64,
    ss: extern union {
        full: u64,
        selector: Gdt.Selector,
    },

    /// Checks if this interrupt occurred in kernel mode.
    pub inline fn isKernel(self: *const InterruptFrame) bool {
        return self.cs.selector == .kernel_code;
    }

    /// Checks if this interrupt occurred in user mode.
    pub inline fn isUser(self: *const InterruptFrame) bool {
        return self.cs.selector == .user_code;
    }

    pub fn print(
        value: *const InterruptFrame,
        writer: std.io.AnyWriter,
        indent: usize,
    ) !void {
        const new_indent = indent + 2;

        try writer.writeAll("InterruptFrame{\n");

        try writer.writeByteNTimes(' ', new_indent);
        try writer.print("interrupt: {s},\n", .{@tagName(value.vector_number.interrupt)});

        try writer.writeByteNTimes(' ', new_indent);
        try writer.print("error code: {},\n", .{value.error_code});

        try writer.writeByteNTimes(' ', new_indent);
        try writer.print("cs: {s},\n", .{@tagName(value.cs.selector)});

        try writer.writeByteNTimes(' ', new_indent);
        try writer.print("ss: {s},\n", .{@tagName(value.ss.selector)});

        try writer.writeByteNTimes(' ', new_indent);
        try writer.print("ds: {s},\n", .{@tagName(value.ds.selector)});

        try writer.writeByteNTimes(' ', new_indent);
        try writer.print("es: {s},\n", .{@tagName(value.es.selector)});

        try writer.writeByteNTimes(' ', new_indent);
        try writer.print("rsp: 0x{x},\n", .{value.rsp});

        try writer.writeByteNTimes(' ', new_indent);
        try writer.print("rip: 0x{x},\n", .{value.rip});

        try writer.writeByteNTimes(' ', new_indent);
        try writer.print("rax: 0x{x},\n", .{value.rax});

        try writer.writeByteNTimes(' ', new_indent);
        try writer.print("rbx: 0x{x},\n", .{value.rbx});

        try writer.writeByteNTimes(' ', new_indent);
        try writer.print("rcx: 0x{x},\n", .{value.rcx});

        try writer.writeByteNTimes(' ', new_indent);
        try writer.print("rdx: 0x{x},\n", .{value.rdx});

        try writer.writeByteNTimes(' ', new_indent);
        try writer.print("rbp: 0x{x},\n", .{value.rbp});

        try writer.writeByteNTimes(' ', new_indent);
        try writer.print("rsi: 0x{x},\n", .{value.rsi});

        try writer.writeByteNTimes(' ', new_indent);
        try writer.print("rdi: 0x{x},\n", .{value.rdi});

        try writer.writeByteNTimes(' ', new_indent);
        try writer.print("r8: 0x{x},\n", .{value.r8});

        try writer.writeByteNTimes(' ', new_indent);
        try writer.print("r9: 0x{x},\n", .{value.r9});

        try writer.writeByteNTimes(' ', new_indent);
        try writer.print("r10: 0x{x},\n", .{value.r10});

        try writer.writeByteNTimes(' ', new_indent);
        try writer.print("r11: 0x{x},\n", .{value.r11});

        try writer.writeByteNTimes(' ', new_indent);
        try writer.print("r12: 0x{x},\n", .{value.r12});

        try writer.writeByteNTimes(' ', new_indent);
        try writer.print("r13: 0x{x},\n", .{value.r13});

        try writer.writeByteNTimes(' ', new_indent);
        try writer.print("r14: 0x{x},\n", .{value.r14});

        try writer.writeByteNTimes(' ', new_indent);
        try writer.print("r15: 0x{x},\n", .{value.r15});

        try writer.writeByteNTimes(' ', new_indent);
        try writer.writeAll("rflags: ");
        try value.rflags.print(writer, new_indent);
        try writer.writeAll(",\n");

        try writer.writeByteNTimes(' ', indent);
        try writer.writeAll("}");
    }

    pub inline fn format(
        value: *const InterruptFrame,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = options;
        _ = fmt;
        return if (@TypeOf(writer) == std.io.AnyWriter)
            print(value, writer, 0)
        else
            print(value, writer.any(), 0);
    }

    fn __helpZls() void {
        InterruptFrame.print(undefined, @as(std.fs.File.Writer, undefined), 0);
    }
};

pub const init = struct {
    /// Ensure that any exceptions/faults that occur are handled.
    ///
    /// The `initial_interrupt_handler` will be set as the initial interrupt handler for all interrupts.
    pub fn initInterrupts() void {
        for (raw_interrupt_handlers, 0..) |raw_handler, i| {
            idt.handlers[i].init(
                .kernel_code,
                .interrupt,
                raw_handler,
            );
        }

        for (&interrupt_handlers) |*handler| {
            handler.* = @ptrCast(&handlers.unhandledInterrupt);
        }

        idt.handlers[@intFromEnum(Interrupt.double_fault)]
            .setStack(@intFromEnum(InterruptStackSelector.double_fault));

        idt.handlers[@intFromEnum(Interrupt.non_maskable_interrupt)]
            .setStack(@intFromEnum(InterruptStackSelector.non_maskable_interrupt));
    }

    /// Switch away from the initial interrupt handlers installed by `initInterrupts` to the standard
    /// system interrupt handlers.
    pub fn loadStandardInterruptHandlers() callconv(core.inline_in_non_debug) void {
        interrupt_handlers[@intFromEnum(Interrupt.per_executor_periodic)] = &handlers.perExecutorPeriodic;
    }

    pub fn loadIdt() void {
        idt.load();
    }

    /// Creates an array of raw interrupt handlers, one for each vector.
    fn makeRawHandlers() [Idt.number_of_handlers](*const fn () callconv(.Naked) void) {
        var raw_handlers_temp: [Idt.number_of_handlers](*const fn () callconv(.Naked) void) = undefined;

        comptime var i = 0;
        inline while (i < Idt.number_of_handlers) : (i += 1) {
            const vector_number: u8 = @intCast(i);
            const interrupt: Interrupt = @enumFromInt(vector_number);

            // if the cpu does not push an error code, we push a dummy error code to ensure the stack
            // is always aligned in the same way for every vector
            const error_code_asm = if (comptime !interrupt.hasErrorCode()) "push $0\n" else "";
            const vector_number_asm = std.fmt.comptimePrint("push ${d}", .{vector_number});
            const data_selector_asm = std.fmt.comptimePrint("mov ${d}, %%ax", .{@intFromEnum(Gdt.Selector.kernel_data)});

            const rawInterruptHandler = struct {
                fn rawInterruptHandler() callconv(.Naked) void {
                    asm volatile (error_code_asm ++
                            vector_number_asm ++ "\n" ++
                            \\push %%rax
                            \\push %%rbx
                            \\push %%rcx
                            \\push %%rdx
                            \\push %%rbp
                            \\push %%rsi
                            \\push %%rdi
                            \\push %%r8
                            \\push %%r9
                            \\push %%r10
                            \\push %%r11
                            \\push %%r12
                            \\push %%r13
                            \\push %%r14
                            \\push %%r15
                            \\mov %%ds, %%rax
                            \\push %%rax
                            \\mov %%es, %%rax
                            \\push %%rax
                            \\push %%rax // make space for interrupt_disable_count
                            \\mov %%rsp, %%rdi
                        ++ "\n" ++ data_selector_asm ++ "\n" ++
                            \\mov %%ax, %%es
                            \\mov %%ax, %%ds
                            \\call interruptHandler
                            \\pop %%rax // pop interrupt_disable_count
                            \\pop %%rax
                            \\mov %%rax, %%es
                            \\pop %%rax
                            \\mov %%rax, %%ds
                            \\pop %%r15
                            \\pop %%r14
                            \\pop %%r13
                            \\pop %%r12
                            \\pop %%r11
                            \\pop %%r10
                            \\pop %%r9
                            \\pop %%r8
                            \\pop %%rdi
                            \\pop %%rsi
                            \\pop %%rbp
                            \\pop %%rdx
                            \\pop %%rcx
                            \\pop %%rbx
                            \\pop %%rax
                            \\add $16, %%rsp
                            \\iretq
                    );
                }
            }.rawInterruptHandler;

            raw_handlers_temp[vector_number] = rawInterruptHandler;
        }

        return raw_handlers_temp;
    }
};

export fn interruptHandler(interrupt_frame: *InterruptFrame) void {
    const executor = arch.rawGetCurrentExecutor();
    interrupt_frame.interrupt_disable_count = executor.interrupt_disable_count;
    defer arch.rawGetCurrentExecutor().interrupt_disable_count = interrupt_frame.interrupt_disable_count;

    executor.interrupt_disable_count += 1;

    interrupt_handlers[@intFromEnum(interrupt_frame.vector_number.interrupt)](interrupt_frame, executor.current_task);
}

const handlers = struct {
    fn unhandledInterrupt(
        interrupt_frame: *InterruptFrame,
        current_task: *kernel.Task,
    ) void {
        _ = current_task;
        core.panicFmt("unhandled interrupt\n{}", .{interrupt_frame}, null);
    }

    fn perExecutorPeriodic(
        interrupt_frame: *InterruptFrame,
        current_task: *kernel.Task,
    ) void {
        _ = interrupt_frame;

        x64.apic.eoi();

        kernel.entry.onPerExecutorPeriodic(current_task);
    }
};

var idt: Idt = .{};
const raw_interrupt_handlers = init.makeRawHandlers();
var interrupt_handlers: [Idt.number_of_handlers]InterruptHandler = undefined; // initialized in `init.initInterrupts`

const std = @import("std");
const core = @import("core");
const kernel = @import("kernel");
const x64 = @import("x64.zig");
const lib_x64 = @import("lib_x64");
const arch = @import("arch");
const Idt = lib_x64.Idt;
const Gdt = lib_x64.Gdt;
const InterruptHandler = arch.interrupts.InterruptHandler;
