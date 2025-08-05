const std = @import("std");
const print = std.debug.print;

const Allocator = std.mem.Allocator;

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};

    const allocator = gpa.allboardocator();
    // can change these for new board
    const cell_count: u8 = 9;
    const board_size: u8 = 3;
    //
    var board = try Board.init(allocator, cell_count, board_size);
    defer board.deinit();


    for (board.cells) |cell| {
        if (cell.order % board.size == 0) {
            print("{d}|\n", .{cell.order});
        } else if (cell.order % board.size == 1) {
            print("|{d}|", .{cell.order});
        } else {
            print("{d}|", .{cell.order});
        }
    }
}

pub const Board = struct {
    cells: []Cell,
    size: u8,
    current_player: Player = .first, // Player whose turn it is
    status: GameStatus = .draw, // Current game status
    allocator: Allocator,

    const Self = @This();

    fn deinit(self: *Self) void {
        self.allocator.free(self.cells);
    }

    fn init(allocator: Allocator, cell_count: u8, size: u8) !Self {
        const cells = try allocator.alloc(Cell, cell_count);
        for (cells, 0..) |*cell, i| {
            cell.* = Cell{ .order = @intCast(i + 1) };
        }
        return Board{
            .cells = cells,
            .current_player = .first,
            .status = .draw,
            .size = size,
            .allocator = allocator,
        };
    }
};
pub const Cell = struct {
    order: u8 = 0, // Order of the cell in the game (1-9)
    player: ?Player = null, // Player who occupies the cell, null if empty
    // allocator: Allocator,
    // const Self = @This();

    // fn init(allocator: Allocator, order: u8) !Self {
    //     return Cell{ .order = order, .player = null, .allocator = allocator };
    // }
    // fn deinit(self: *Self) void {
    //     // If the cell was allocated, free it
    //     self.allocator.free(self);
    // }
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
