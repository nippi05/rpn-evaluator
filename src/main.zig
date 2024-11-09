const std = @import("std");

const assert = std.debug.assert;

pub fn main() !void {
    var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
    defer assert(gpa_impl.deinit() == .ok);
    const gpa = gpa_impl.allocator();

    var inputs = std.ArrayList([]const u8).init(gpa);
    defer inputs.deinit();
    var arg_iterator = try std.process.argsWithAllocator(gpa);
    _ = arg_iterator.next(); // Program path
    while (arg_iterator.next()) |arg| {
        try inputs.append(arg);
    }

    const result = try evaluateRPN(gpa, inputs.items);
    std.debug.print("The result is: {}", .{result});
}

fn evaluateRPN(gpa: std.mem.Allocator, input: [][]const u8) !f64 {
    var stack = std.ArrayList(f64).init(gpa);
    defer stack.deinit();
    for (input) |entry| {
        std.debug.print("Current entry: \"{s}\"", .{entry});
        assert(entry.len > 0);
        if (std.ascii.isDigit(entry[0])) {
            const number = try std.fmt.parseFloat(f64, entry);
            try stack.append(number);
            continue;
        }
        // If it isn't a digit it's a operator + - / *
        assert(entry.len == 1);
        const operator = asOperator(entry[0]);
        const second = stack.pop();
        const first = stack.pop();
        const result = operator.operate(first, second);
        try stack.append(result);
    }
    assert(stack.items.len == 1);
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
};

fn asOperator(char: u8) Operator {
    return switch (char) {
        '+' => .plus,
        '-' => .minus,
        '*' => .times,
        '/' => .over,
        else => unreachable,
    };
}
