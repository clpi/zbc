const std = @import("std");
const hash_map = std.hash_map;
const math = std.math;
const Alloc = std.mem.Allocator;

pub const Self = @This();
pub const Graph = Self;

pub const Error = error{
    OutOfMemory,
    EdgeNotFound,
    VertexNotFound,
};

pub fn StronglyConnected(
    comptime Index: type,
) type {
    return struct {
        list: std.ArrayList(std.ArrayList(Index)),

        pub const Iterator = struct {
            list: *const std.ArrayList(std.ArrayList(Index)),
            index: usize = 0,

            pub fn next(self: *@This()) ?[]Index {
                if (self.list.items.len == 0 or
                    self.list.items.len <= self.index) return null;
                defer self.index += 1;
                return self.list.items[self.index].items;
            }
        };

        pub fn init(a: std.mem.Allocator) @This() {
            return @This(){
                .list = std.ArrayList(std.ArrayList(Index)).init(a),
            };
        }
        pub fn deinit(self: *@This()) void {
            for (self.list.items) |v| {
                v.deinit();
            }
            self.list.deinit();
        }
    };
}

pub fn Directed(
    comptime T: type,
    comptime Context: type,
    comptime Value: type,
    comptime Index: type,
) type {
    comptime hash_map.verifyContext(Context, T, T, Index, false);
    const AdjMapValue: type = hash_map.AutoHashMap(Index, Value);
    const AdjMap: type = hash_map.AutoHashMap(Index, AdjMapValue);
    const ValMap: type = hash_map.AutoHashMap(Index, AdjMapValue);
    return struct {
        alloc: Alloc,
        ctx: Context,
        adjOut: AdjMap,
        adjIn: AdjMap,
        vals: ValMap,
        const DirectedGraph: type = @This();
        const Size: type = AdjMap.Size;

        pub fn initContext(a: Alloc, ctx: Context) @This() {
            return .{
                .alloc = a,
                .ctx = ctx,
                .adjOut = AdjMap.init(a),
                .adjIn = AdjMap.init(a),
                .vals = ValMap.init(a),
            };
        }
        pub fn init(a: Alloc) @This() {
            if (@sizeOf(Context) != 0)
                @compileError("Context non zero sized. use InitContext");
            return initContext(a, undefined);
        }
        pub fn deinit(self: *@This()) void {
            var it = self.adjOut.iterator();
            while (it.next()) |kv| kv.value_ptr.deinit();
            it = self.adjIn.iterator();
            while (it.next()) |kv| kv.value_ptr.deinit();
            self.adjOut.deinit();
            self.adjIn.deinit();
            self.vals.deinit();
            self.* = undefined;
        }

        pub fn add(self: *@This(), v: T) !void {
            const h = self.ctx.hash(v);
            if (self.adjOut.contains(h)) return;
            try self.adjOut.put(h, AdjMapValue.init(self.alloc));
            try self.adjIn.put(h, AdjMapValue.init(self.alloc));
            try self.vals.put(h, v);
        }

        pub fn rm(self: *@This(), v: T) void {
            const h = self.ctx.hash(v);
            _ = self.vals.remove(h);
            if (self.adjOut.getPtr(h)) |map| {
                var it = map.iterator();
                while (it.next()) |kv| {
                    if (self.adjIn.getPtr(kv.key_ptr.*)) |inMap|
                        _ = inMap.remove(h);
                }
                map.deinit();
                _ = self.adjOut.remove(h);
            }
            if (self.adjIn.getPtr(h)) |map| {
                var it = map.iterator();
                while (it.next()) |kv| {
                    if (self.adjOut.getPtr(kv.key_ptr.*)) |inMap|
                        _ = inMap.remove(h);
                }
                map.deinit();
                _ = self.adjOut.remove(h);
            }
        }

        pub fn contains(self: *@This(), v: T) bool {
            return self.vals.contains(self.ctx.hash(v));
        }
        pub fn lookup(self: *@This(), hash: u64) ?T {
            return self.vals.get(hash);
        }
        pub fn addEdge(self: *@This(), from: T, to: T, weight: Value) !void {
            const h1 = self.ctx.hash(from);
            const h2 = self.ctx.hash(to);
            const mapOut = self.adjOut.getPtr(h1) orelse return Error.VertexNotFound;
            const mapIn = self.adjIn.getPtr(h2) orelse return Error.VertexNotFound;
            try mapOut.put(h2, weight);
            try mapIn.put(h1, weight);
        }

        pub fn rmEdge(self: *@This(), from: T, to: T) void {
            const h1 = self.ctx.hash(from);
            const h2 = self.ctx.hash(to);
            if (self.adjOut.getPtr(h1)) |m| {
                m.remove(h2);
            } else unreachable;
            if (self.adjIn.getPtr(h2)) |m| {
                _ = m.remove(h1);
            } else unreachable;
        }

        pub fn getEdge(self: *const @This(), from: T, to: T) ?Value {
            const h1 = self.ctx.hash(from);
            const h2 = self.ctx.hash(to);
            if (self.adjOut.getPtr(h1)) |m| {
                return m.get(h2);
            } else unreachable;
        }

        pub fn reverse(self: *const @This()) @This() {
            return @This(){
                .alloc = self.alloc,
                .ctx = self.ctx,
                .adjOut = self.adjIn,
                .adjIn = self.adjOut,
                .vals = self.vals,
            };
        }

        pub fn cloneAdjMap(m: *const AdjMap) !AdjMap {
            var new = try m.clone();
            var it = new.iterator();
            while (it.next()) |kv|
                try new.put(kv.key_ptr.*, try kv.value_ptr.clone());
            return new;
        }

        pub fn clone(self: *const @This()) !@This() {
            return @This(){
                .alloc = self.alloc,
                .ctx = self.ctx,
                .adjOut = try cloneAdjMap(&self.adjOut),
                .adjIn = try cloneAdjMap(&self.adjIn),
                .vals = try self.vals.clone(),
            };
        }

        pub fn vertexCount(self: *const @This()) AdjMap.Size {
            return self.vals.count();
        }

        pub fn edgeCount(self: *const @This()) AdjMap.Size {
            var c: Size = 0;
            var it = self.adjOut.iterator();
            while (it.next()) |kv|
                c += kv.value_ptr.count();
            return c;
        }

        // TODO: implmeent
        pub fn stronglyConnected(self: *const @This()) StronglyConnected(Index) {
            _ = self;
        }

        /// Return set of cycles in graph
        // TODO implement
        pub fn cycles(self: *const @This()) ?StronglyConnected(Index) {
            var connected = self.strongly;
            var i: usize = 0;
            while (i < connected) : (i += 1) {}
        }

        pub const DFSIterator = struct {
            g: *const DirectedGraph,
            stack: std.ArrayList(Index),
            visited: std.AutoHashMap(u64, void),
            curr: ?Index,

            pub fn init(g: *const DirectedGraph, start: T) !@This() {
                const h = g.ctx.hash(start);
                if (!g.vals.contains(h))
                    return Graph.Error.VertexNotFound;
                return @This(){
                    .g = g,
                    .stack = std.ArrayList(Index).init(g.alloc),
                    .visited = std.AutoHashMap(Index, void).init(g.alloc),
                    .curr = h,
                };
            }

            pub fn deinit(self: *@This()) void {
                self.stack.deinit();
                self.visited.deinit();
            }

            pub fn next(self: *@This()) !?Index {
                if (self.curr == null) return null;
                const res = self.curr orelse unreachable;
                try self.visited.put(res, {});
                if (self.g.adjOut.getPtr(res)) |m| {
                    var it = m.keyIterator();
                    while (it.next()) |tgt| {
                        if (!self.visited.contains(tgt.*)) {
                            try self.stack.append(tgt.*);
                        }
                    }
                }
                self.curr = null;
                while (self.stack.popOrNull()) |nextVal| {
                    if (!self.visited.contains(nextVal)) {
                        self.curr = nextVal;
                        break;
                    }
                }
                return res;
            }
        };

        pub fn dfsIterator(self: *const @This(), start: T) Self.Error!void {
            return DFSIterator.init(self, start);
        }
    };
}

test "add and remove vertex" {
    const gtype = Graph.Directed([]const u8, std.hash_map.StringContext);
    var g = gtype.init(std.testing.allocator);
    defer g.deinit();
}
