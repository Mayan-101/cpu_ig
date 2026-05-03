`timescale 1ns / 1ps

module cla_32bit (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire        cin,
    output wire [31:0] sum,
    output wire        cout,
    output wire        overflow
);

    // Internal wires for the 16-bit Group Generate/Propagate signals
    wire [1:0] G_16;
    wire [1:0] P_16;
    
    // Internal carry crossing the 16-bit boundary
    wire c16;

    //  Third-Level Lookahead Logic 
    // Compute the carry into the upper 16 bits
    assign c16 = G_16[0] | (P_16[0] & cin);
    
    // Compute final carry out
    assign cout = G_16[1] | (P_16[1] & c16);

    //  Instantiations 
    // Lower 16 bits (0 to 15)
    cla_16bit cla_lower (
        .a(a[15:0]),
        .b(b[15:0]),
        .cin(cin),
        .sum(sum[15:0]),
        .group_G(G_16[0]),
        .group_P(P_16[0])
    );

    // Upper 16 bits (16 to 31)
    cla_16bit cla_upper (
        .a(a[31:16]),
        .b(b[31:16]),
        .cin(c16),         // Driven by parallel lookahead, not ripple
        .sum(sum[31:16]),
        .group_G(G_16[1]),
        .group_P(P_16[1])
    );

    //  Signed Overflow Detection 
    // Overflow occurs if two positive numbers yield a negative sum,
    // or if two negative numbers yield a positive sum.
    assign overflow = (a[31] == b[31]) && (sum[31] != a[31]);

endmodule
