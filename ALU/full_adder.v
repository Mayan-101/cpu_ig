`timescale 1ns / 1ps

module full_adder (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire sum,
    output wire cout
);

    // Internal wires connecting the half adders
    wire w_sum1;
    wire w_carry1;
    wire w_carry2;

    // First Half Adder: Adds a and b
    half_adder ha1 (
        .a(a),
        .b(b),
        .sum(w_sum1),
        .cout(w_carry1)
    );

    // Second Half Adder: Adds the sum of (a+b) to cin
    half_adder ha2 (
        .a(w_sum1),
        .b(cin),
        .sum(sum),
        .cout(w_carry2)
    );

    // Final Carry Out: True if either half adder generated a carry
    assign cout = w_carry1 | w_carry2;

endmodule
