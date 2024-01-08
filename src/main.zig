const std = @import("std");
const builtin = @import("builtin");
const mem = std.mem;
const proc = std.process;
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const fast_exit = builtin.mode != .Debug;
const llibc = builtin.link_libc;

fn exit(msg: []const u8) u8 {
    print("\x1b[33;1m[ERR]\x1b[0m {s}\n", .{msg});
    if (fast_exit) proc.exit(1);
    return 1;
}

pub fn main() u8 {
    const a = if (llibc) std.heap.raw_c_allocator else gpa.allocator();
    defer if (llibc) {
        _ = gpa.deinit();
    };
    var arena_inst = ArenaAllocator.init(a);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const args = proc.argsAlloc(arena) catch return exit("out of mem\n");
    _ = args;
    const zname = std.fs.selfExePathAlloc(a) catch return exit("unable to find zbc exe\n");
    defer a.free(zname);
    print("HI WORLD\n", .{});
    return 0;
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
