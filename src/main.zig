const std = @import("std");
const print = std.debug.print;

const Allocator = std.mem.Allocator;

pub fn main() !void {
    print("Start", .{});

    const board = try create_board();

    print("Board created: {any}\n", .{board});
}

fn create_board() !Board {
    const board: Board = .{ .cells = [9]Cell{
        .{},
        .{},
    }, .current_player = .first, .status = .draw };
    return board;
}

pub const Board = struct {
    cells: [9]Cell, // 3x3 grid represented as a flat array of 9 cells
    current_player: Player = .first, // Player whose turn it is
    status: GameStatus = .draw, // Current game status
    allocator: Allocator,

    const Self = @This();

    fn deinit() void {}

    fn init(allocator: Allocator) !Self {
        return Board{
            .cells = [_]Cell{ .{}, .{}, .{}, .{}, .{}, .{}, .{}, .{}, .{} },
            .current_player = .first,
            .status = .draw,
            .allocator = allocator,
        };
    }
};
pub const Cell = struct {
    empty: bool = true,
    player: ?Player = null, // Player who occupies the cell, null if empty
    allocator: Allocator,
    const Self = @This();

    fn init(allocator: Allocator) Cell {
        return Cell{ .empty = true, .player = null, .allocator = allocator};
    }
};

pub const Player = enum {
    first,
    second,
};
pub const GameStatus = enum {
    first_player_won,
    second_player_won,
    draw,
};
