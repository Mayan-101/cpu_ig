`timescale 1ns / 1ps

module mantissa_aligner (
    input  wire [7:0]  exp_a,
    input  wire [23:0] mant_a, // Includes implicit bit
    input  wire [7:0]  exp_b,
    input  wire [23:0] mant_b, // Includes implicit bit
    output reg  [24:0] aligned_a,
    output reg  [24:0] aligned_b,
    output reg  [7:0]  common_exp
);

    reg [7:0] exp_diff;

    always @(*) begin
        if (exp_a >= exp_b) begin
            // A is larger or equal
            common_exp = exp_a;
            exp_diff   = exp_a - exp_b;
            aligned_a  = {1'b0, mant_a}; // Pad with carry bit
            
            // Shift B right by the difference
            if (exp_diff >= 8'd25)
                aligned_b = 25'b0;
            else
                aligned_b = {1'b0, mant_b} >> exp_diff;
        end 
        else begin
            // B is larger
            common_exp = exp_b;
            exp_diff   = exp_b - exp_a;
            aligned_b  = {1'b0, mant_b};
            
            // Shift A right by the difference
            if (exp_diff >= 8'd25)
                aligned_a = 25'b0;
            else
                aligned_a = {1'b0, mant_a} >> exp_diff;
        end
    end

endmodule
