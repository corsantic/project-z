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
    const first_player = Player.init("Player 1", "*", PlayerOrder.first);
    const second_player = Player.init("Player 2", "#", PlayerOrder.second);

    // Initialize board with first player
    var board = try Board.init(allocator, cell_count, board_size, &first_player);
    defer board.deinit();

    const stdin = std.io.getStdIn().reader();
    // stdout is a std.io.Writer
    const stdout = std.io.getStdOut().writer();

    try board.draw(stdout, &first_player, &second_player);
    try processInput(stdin, stdout, &board, &first_player, &second_player);
}

fn processInput(stdin: anytype, stdout: anytype, board: *Board, first_player: *const Player, second_player: *const Player) !void {
    var i: i32 = 0;

    while (true) : (i += 1) {
        var buf: [10]u8 = undefined;
        try stdout.print("{s} - Please enter your number: ", .{board.current_player.name});

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
                // std.debug.print("{any}\n", .{num});
                for (board.cells) |*cell| {
                    if (cell.order == num and cell.player == null) {
                        cell.player = board.current_player;
                        board.changePlayer(first_player, second_player);
                        break;
                    }
                }
            }
        }
        try board.draw(stdout, first_player, second_player);
    }
}
pub const Board = struct {
    cells: []Cell,
    size: u8,
    current_player: *const Player, // Player whose turn it is
    status: GameStatus, // Current game status
    allocator: Allocator,

    const Self = @This();

    fn deinit(self: *Self) void {
        self.allocator.free(self.cells);
    }

    fn init(allocator: Allocator, cell_count: u8, size: u8, player: *const Player) !Self {
        const cells = try allocator.alloc(Cell, cell_count);
        for (cells, 0..) |*cell, i| {
            cell.* = Cell{ .order = @intCast(i + 1) };
        }
        return Board{
            .cells = cells,
            .current_player = player,
            .status = GameStatus.draw,
            .size = size,
            .allocator = allocator,
        };
    }

    fn draw(self: *Self, writer: anytype, first_player: *const Player, second_player: *const Player) !void {
        for (self.cells) |cell| {
            var buf: [5]u8 = undefined;
            var cell_value: []const u8 = std.fmt.bufPrint(&buf, "{}", .{cell.order}) catch "err";

            if (cell.player == first_player) {
                cell_value = first_player.symbol;
            } else if (cell.player == second_player) {
                cell_value = second_player.symbol;
            }

            if (cell.order % self.size == 0) {
                try writer.print("{s}|\n", .{cell_value});
            } else if (cell.order % self.size == 1) {
                try writer.print("|{s}|", .{cell_value});
            } else {
                try writer.print("{s}|", .{cell_value});
            }
        }
    }
    fn changePlayer(self: *Self, first_player: *const Player, second_player: *const Player) void {
        if (self.current_player == first_player) {
            self.current_player = second_player;
        } else {
            self.current_player = first_player;
        }
    }
};
pub const Cell = struct {
    order: u8 = 0, // Order of the cell in the game (1-9)
    player: ?*const Player = null, // Player who occupies the cell, null if empty
};

pub const Player = struct {
    name: []const u8, // Name of the player
    symbol: []const u8, // Symbol used by the player
    player: PlayerOrder, // Order of the player in the game

    fn init(name: []const u8, symbol: []const u8, player_order: PlayerOrder) Player {
        return Player{
            .name = name,
            .symbol = symbol,
            .player = player_order,
        };
    }
};
pub const PlayerOrder = enum {
    first,
    second,
};
pub const GameStatus = enum {
    first_player_won,
    second_player_won,
    draw,
};

const testing = std.testing;
test "test board init" {
    var gpa = std.heap.DebugAllocator(.{}){};
    const allocator = gpa.allocator();
    const first_player = Player.init("Player 1", "*", PlayerOrder.first);

    var board = try Board.init(allocator, 9, 3, &first_player);
    defer board.deinit();

    try testing.expect(board.cells.len == 9);
    try testing.expect(board.size == 3);
    try testing.expect(board.current_player == &first_player);
}

test "test board draw" {
    var gpa = std.heap.DebugAllocator(.{}){};
    const allocator = gpa.allocator();
    const first_player = Player.init("Player 1", "*", PlayerOrder.first);
    const second_player = Player.init("Player 2", "#", PlayerOrder.second);
    var board = try Board.init(allocator, 9, 3, &first_player);
    defer board.deinit();
    // Check if the board is printed correctly
    var output_buffer: [128]u8 = undefined;
    var output_stream = std.io.fixedBufferStream(&output_buffer);
    const writer = output_stream.writer().any();

    const expected_output = "|1|2|3|\n|4|5|6|\n|7|8|9|\n";
    try board.draw(writer, &first_player, &second_player);
    
    // Only compare the part of the buffer that was written to
    const output = output_buffer[0..output_stream.pos];
    try std.testing.expectEqualStrings(expected_output, output);
}
