`timescale 1ns / 1ps

/**
 * Module: float_ftoi
 * Description: Converts an IEEE-754 single-precision float to a 32-bit signed integer.
 */
module float_ftoi (
    input  wire [31:0] float_in,
    output reg  [31:0] int_out
);

    reg        sign;
    reg [7:0]  biased_exp;
    reg [22:0] mant;
    reg [23:0] mant_with_hidden;
    integer    exp;
    reg [31:0] abs_int;

    always @(*) begin
        sign = float_in[31];
        biased_exp = float_in[30:23];
        mant = float_in[22:0];
        mant_with_hidden = {1'b1, mant};
        exp = biased_exp - 127;

        if (biased_exp == 8'd0) begin
            // Subnormal or Zero
            int_out = 32'd0;
        end else if (biased_exp == 8'hFF) begin
            // Infinity or NaN
            int_out = sign ? 32'h80000000 : 32'h7FFFFFFF;
        end else if (exp < 0) begin
            // Underflow (value < 1.0)
            int_out = 32'd0;
        end else if (exp > 30) begin
            // Potential Overflow
            if (exp == 31 && sign && mant == 0) begin
                // Special case: -2147483648
                int_out = 32'h80000000;
            end else begin
                int_out = sign ? 32'h80000000 : 32'h7FFFFFFF;
            end
        end else begin
            // Normal range 0 <= exp <= 30
            if (exp >= 23) begin
                abs_int = {8'd0, mant_with_hidden} << (exp - 23);
            end else begin
                abs_int = {8'd0, mant_with_hidden} >> (23 - exp);
            end
            
            int_out = sign ? (~abs_int + 1'b1) : abs_int;
        end
    end

endmodule
