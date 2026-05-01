`timescale 1ns / 1ps

module booth_step (
    input  wire [64:0] acc,          // [64:33] = High, [32:1] = Multiplier, [0] = implied 0
    input  wire [31:0] multiplicand,
    input  wire [2:0]  booth_code,   // From encoder
    output wire [64:0] new_acc
);

    wire is_neg    = booth_code[2];
    wire is_mag    = booth_code[1];
    wire is_double = booth_code[0];

    // Sign extend multiplicand to 33 bits to prevent overflow during addition
    wire [32:0] m_ext = {multiplicand[31], multiplicand};
    
    // Determine base value (1x or 2x)
    wire [32:0] pp_base = is_double ? (m_ext << 1) : m_ext;
    
    // Apply sign and magnitude (0 handling)
    wire [32:0] pp = is_mag ? (is_neg ? (~pp_base + 1) : pp_base) : 33'b0;

    // Add partial product to upper half of accumulator
    // Upper half is acc[64:33], which is 32 bits. We sign extend it to 33 bits.
    wire [32:0] acc_high = {acc[64], acc[64:33]};
    wire [32:0] adder_out = acc_high + pp;

    // Arithmetic Shift Right by 2 (Radix-4)
    assign new_acc = {adder_out[32], adder_out[32:0], acc[32:2]};

endmodule
