`timescale 1ns / 1ps

module float_mul (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output reg  [31:0] result, // Changed to reg because it's assigned in always block
    output wire        of_flag,
    output wire        uf_flag
);

    // 1. Unpack operands - Capture all flags
    wire s1, s2;
    wire [7:0] e1, e2;
    wire [22:0] m1, m2;
    wire z1, z2, inf1, inf2, nan1, nan2;

    float_unpacker u1 (
        .float32(a), .sign(s1), .exponent(e1), .mantissa(m1), 
        .is_zero(z1), .is_inf(inf1), .is_nan(nan1)
    );
    float_unpacker u2 (
        .float32(b), .sign(s2), .exponent(e2), .mantissa(m2), 
        .is_zero(z2), .is_inf(inf2), .is_nan(nan2)
    );

    // 2. Extract components
    wire final_s = s1 ^ s2;
    wire [23:0] imp_m1 = {|e1, m1};
    wire [23:0] imp_m2 = {|e2, m2};

    // 3. Mantissa Multiplication
    wire [47:0] prod_m = imp_m1 * imp_m2; 
    
    // 4. Exponent Calculation (Signed to handle bias correctly)
    wire signed [9:0] exp_sum = e1 + e2 - 127;

    // 5. Normalization
    wire [7:0] final_e;
    wire [22:0] final_m;
    
    // Pass the top part of the product to the normalizer
    float_norm norm_unit (
        .raw_mant({23'b0, prod_m[47:23]}), 
        .raw_exp(exp_sum[8:0]), 
        .final_exp(final_e),
        .final_mant(final_m),
        .done_uf(uf_flag),
        .done_of(of_flag)
    );

    // 6. Final Result Multiplexer (Special Cases)
    always @(*) begin
        if (nan1 || nan2) 
            result = 32'h7FC00000; // NaN
        else if ((inf1 && !z2) || (inf2 && !z1)) 
            result = {final_s, 8'hFF, 23'h0}; // Infinity
        else if (z1 || z2 || (inf1 && z2) || (inf2 && z1))
            result = {final_s, 31'b0}; // Zero (or Inf * 0 case)
        else
            result = {final_s, final_e, final_m};
    end

endmodule
