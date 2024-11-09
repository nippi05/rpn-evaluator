const std = @import("std");

const assert = std.debug.assert;

pub fn main() !void {
    var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
    defer assert(gpa_impl.deinit() == .ok);
    const gpa = gpa_impl.allocator();

    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);
    if (args.len < 2) {
        return error.ExpectedExpression;
    }

    const result = try evaluateRPN(gpa, args[1..]);
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{}\n", .{result});
}

fn evaluateRPN(gpa: std.mem.Allocator, input: [][]const u8) error{ InvalidOperator, NonTerminating, InvalidNumber, InvalidExpression, OutOfMemory }!f64 {
    var stack = std.ArrayList(f64).init(gpa);
    defer stack.deinit();
    for (input) |entry| {
        assert(entry.len > 0); // argsAlloc asserts this
        if (std.ascii.isDigit(entry[0]) or entry[0] == '-') {
            const number = std.fmt.parseFloat(f64, entry) catch return error.InvalidNumber;
            try stack.append(number);
            continue;
        }
        // If it isn't a digit it's a operator + - / *
        if (entry.len != 1) {
            return error.InvalidOperator;
        }
        const operator = try Operator.from(entry[0]);
        const second = stack.popOrNull() orelse return error.InvalidExpression;
        const first = stack.popOrNull() orelse return error.InvalidExpression;
        const result = operator.operate(first, second);
        try stack.append(result);
    }
    if (stack.items.len != 1) {
        return error.NonTerminating;
    }
    return stack.items[0];
}

const Operator = enum {
    plus,
    minus,
    times,
    over,

    fn operate(operator: Operator, first: f64, second: f64) f64 {
        return switch (operator) {
            .plus => first + second,
            .minus => first - second,
            .times => first * second,
            .over => first / second,
        };
    }

    fn from(char: u8) !Operator {
        return switch (char) {
            '+' => .plus,
            '-' => .minus,
            'x' => .times,
            '/' => .over,
            else => return error.InvalidOperator,
        };
    }
};
