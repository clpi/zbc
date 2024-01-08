const std = @import("std");

pub const Id = enum(u32) {
    unused = 0,
    generated = 1,
    _,
};
