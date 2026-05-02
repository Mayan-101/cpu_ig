`timescale 1ns / 1ps

module tb_mantissa_aligner;

    reg [7:0]  exp_a, exp_b;
    reg [23:0] mant_a, mant_b;
    wire [24:0] aligned_a, aligned_b;
    wire [7:0]  common_exp;

    mantissa_aligner uut (
        .exp_a(exp_a), .mant_a(mant_a),
        .exp_b(exp_b), .mant_b(mant_b),
        .aligned_a(aligned_a), .aligned_b(aligned_b),
        .common_exp(common_exp)
    );

    initial begin
        $display("Starting Mantissa Aligner Tests...");
        $display(" Case | ExpA | ExpB | Aligned A | Aligned B | Common Exp");
        $display("------------------------------------------------------------");

        // Case 1: Same exponent (No shift)
        exp_a = 8'd127; mant_a = 24'h800000; // 1.0
        exp_b = 8'd127; mant_b = 24'hC00000; // 1.5
        #10;
        $display(" Equal|  %0d |  %0d |  %h |  %h |   %0d", exp_a, exp_b, aligned_a, aligned_b, common_exp);

        // Case 2: Diff = 1 (Shift by 1)
        exp_a = 8'd128; mant_a = 24'h800000; 
        exp_b = 8'd127; mant_b = 24'h800000; 
        #10;
        $display(" Diff1|  %0d |  %0d |  %h |  %h |   %0d", exp_a, exp_b, aligned_a, aligned_b, common_exp);

        // Case 3: Diff = 10
        exp_a = 8'd137; mant_a = 24'hFFFFFF; 
        exp_b = 8'd127; mant_b = 24'h800000; 
        #10;
        $display(" Dif10|  %0d |  %0d |  %h |  %h |   %0d", exp_a, exp_b, aligned_a, aligned_b, common_exp);

        // Case 4: Diff >= 24 (B disappears)
        exp_a = 8'd160; mant_a = 24'h800000; 
        exp_b = 8'd127; mant_b = 24'h800000; 
        #10;
        $display(" Dif25|  %0d |  %0d |  %h |  %h |   %0d", exp_a, exp_b, aligned_a, aligned_b, common_exp);

        $finish;
    end

endmodule