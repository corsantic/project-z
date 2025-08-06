const std = @import("std");
const builtin = @import("builtin");

const print = std.debug.print;

const Allocator = std.mem.Allocator;

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};

    const allocator = gpa.allocator();
    // can change these for new board
    const cell_count: u8 = 9;
    const board_size: u8 = 3;
    var board = try Board.init(allocator, cell_count, board_size);
    defer board.deinit();

    const stdin = std.io.getStdIn().reader();
    // stdout is a std.io.Writer
    const stdout = std.io.getStdOut().writer();

    board.draw();
    try processInput(stdin, stdout, &board);
}

fn processInput(stdin: anytype, stdout: anytype, board: *Board) !void {
    var i: i32 = 0;
    while (true) : (i += 1) {
        var buf: [10]u8 = undefined;
        try stdout.print("{any} - Please enter your number: ", .{board.current_player});

        if (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            var number = line;

            if (builtin.os.tag == .windows) {
                //in windows lines are terminated by \r\n
                //we need to strip out the \r
                number = @constCast(std.mem.trimRight(u8, number, "\r"));
            }
            if (number.len == 0) {
                break;
            }
            const parsed = std.fmt.parseInt(u8, number, 10) catch null;

            if (parsed) |num| {
                std.debug.print("{any}\n", .{num});
                for (board.cells) |*cell| {
                    if (cell.order == num and cell.player == null) {
                        cell.player = board.current_player;
                        board.changePlayer();
                        break;
                    }
                }
            }
        }
        board.draw();
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

    fn draw(self: *Self) void {
        for (self.cells) |cell| {
            var buf: [5]u8 = undefined;
            var cell_value: []const u8 = std.fmt.bufPrint(&buf, "{}", .{cell.order}) catch "err";

            if (cell.player == Player.first) {
                cell_value = "*";
            } else if (cell.player == Player.second) {
                cell_value = "#";
            }

            if (cell.order % self.size == 0) {
                print("{s}|\n", .{cell_value});
            } else if (cell.order % self.size == 1) {
                print("|{s}|", .{cell_value});
            } else {
                print("{s}|", .{cell_value});
            }
        }
    }
    fn changePlayer(self: *Self) void {
        if (self.current_player == Player.first) {
            self.current_player = Player.second;
        } else {
            self.current_player = Player.first;
        }
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
