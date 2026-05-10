`timescale 1ns / 1ps

module booth_step (
    input  wire [68:0] acc,          // [68:35] = High (34 bits), [34:1] = Multiplier (34 bits), [0] = implied 0
    input  wire [33:0] multiplicand,
    input  wire [2:0]  booth_code,   // From encoder
    output wire [68:0] new_acc
);

    wire is_neg    = booth_code[2];
    wire is_mag    = booth_code[1];
    wire is_double = booth_code[0];

    // Sign extend multiplicand to 35 bits to prevent overflow during addition
    wire [34:0] m_ext = {multiplicand[33], multiplicand};
    
    // Determine base value (1x or 2x)
    wire [34:0] pp_base = is_double ? (m_ext << 1) : m_ext;
    
    // Apply sign and magnitude (0 handling)
    wire [34:0] pp = is_mag ? (is_neg ? (~pp_base + 1) : pp_base) : 35'b0;

    // Add partial product to upper half of accumulator
    // Upper half is acc[68:35], which is 34 bits. We sign extend it to 35 bits.
    wire [34:0] acc_high = {acc[68], acc[68:35]};
    wire [34:0] adder_out = acc_high + pp;

    // Arithmetic Shift Right by 2 (Radix-4)
    // {Sign, Sign, Result[34:0], LowBits[34:2]}
    assign new_acc = {adder_out[34], adder_out[34:0], acc[34:2]};

endmodule

