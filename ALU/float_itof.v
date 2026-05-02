`timescale 1ns / 1ps

/**
 * Module: float_itof
 * Description: Converts a 32-bit signed integer to IEEE-754 single-precision float.
 */
module float_itof (
    input  wire [31:0] int_in,
    output reg  [31:0] float_out
);

    integer i;
    reg [4:0]  pos;
    reg        found;
    reg [31:0] abs_int;
    reg        sign;
    reg [7:0]  exp;
    reg [22:0] mant;

    always @(*) begin
        if (int_in == 32'd0) begin
            float_out = 32'd0;
        end else begin
            // 1. Sign and Absolute Value
            sign = int_in[31];
            abs_int = sign ? (~int_in + 1'b1) : int_in;

            // 2. Find Leading One (Position of MSB)
            pos = 0;
            found = 0;
            for (i = 31; i >= 0; i = i - 1) begin
                if (abs_int[i] && !found) begin
                    pos = i;
                    found = 1;
                end
            end

            // 3. Calculate Exponent (Bias = 127)
            exp = 8'd127 + pos;

            // 4. Align Mantissa (Shift abs_int to have the MSB at bit 23)
            // The hidden bit is at pos, we want bit 23 to be the bit just below the hidden bit? 
            // No, IEEE-754 mantissa is the bits AFTER the leading 1.
            // If pos = 0 (val = 1), exp = 127, mantissa = 0.
            // If pos = 23 (val = 2^23), exp = 150, mantissa = bits [22:0].
            
            if (pos <= 23) begin
                mant = abs_int[22:0] << (23 - pos);
            end else begin
                mant = abs_int[pos-1 -: 23]; // Take 23 bits below the MSB
                // Simple truncation for now (no rounding)
            end

            float_out = {sign, exp, mant};
        end
    end

endmodule
