`timescale 1ns / 1ps

module sub_32bit (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [31:0] diff,
    output wire        borrow,   // Logic: NOT(cout) for subtraction
    output wire        overflow
);

    wire [31:0] not_b;
    wire cout_internal;

    // Bitwise NOT of B
    assign not_b = ~b;

    // Reuse the 32-bit CLA
    // Subtraction is A + (~B) + 1
    cla_32bit adder_inst (
        .a(a),
        .b(not_b),
        .cin(1'b1),
        .sum(diff),
        .cout(cout_internal),
        .overflow(overflow)
    );

    // In unsigned subtraction, a borrow occurs if A < B.
    // In Verilog addition A + ~B + 1, this corresponds to cout being 0.
    assign borrow = ~cout_internal;

endmodule
