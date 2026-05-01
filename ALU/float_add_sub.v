`timescale 1ns / 1ps

module float_add_sub (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire        op, 
    output wire [31:0] result,
    output wire        of_flag,
    output wire        uf_flag
);

    wire s1, s2;
    wire [7:0] e1, e2;
    wire [22:0] m1, m2;
    float_unpacker u1 (a, s1, e1, m1, , , , );
    float_unpacker u2 (b, s2, e2, m2, , , , );

    wire [23:0] imp_m1 = {|e1, m1};
    wire [23:0] imp_m2 = {|e2, m2};

    wire [24:0] am1, am2;
    wire [7:0] common_exp;
    mantissa_aligner align (e1, imp_m1, e2, imp_m2, am1, am2, common_exp);

    wire eff_sub = (op) ? (s1 == s2) : (s1 != s2);
    
    reg [24:0] res_m; 
    always @(*) begin
        if (eff_sub) res_m = (am1 >= am2) ? (am1 - am2) : (am2 - am1);
        else         res_m = am1 + am2;
    end

    wire final_s = (op) ? ((am1 >= am2) ? s1 : !s2) : ((am1 >= am2) ? s1 : s2);

    // normalization
    wire [7:0] final_e;
    wire [22:0] final_m;
    
    float_norm norm_unit (
        .raw_mant({23'b0, res_m}), // Pad 25-bit sum to 48-bit normalizer input
        .raw_exp({1'b0, common_exp}),
        .final_exp(final_e),
        .final_mant(final_m),
        .done_uf(uf_flag),
        .done_of(of_flag)
    );

    assign result = (res_m == 0) ? 32'b0 : {final_s, final_e, final_m};

endmodule