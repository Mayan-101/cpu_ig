`timescale 1ns / 1ps

module half_adder (
    input  wire a,
    input  wire b,
    output wire sum,
    output wire cout
);

    // Continuous assignment for sum and carry out
    assign sum  = a ^ b;  // XOR gate
    assign cout = a & b;  // AND gate

endmodule
