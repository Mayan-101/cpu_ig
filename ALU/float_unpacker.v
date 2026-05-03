`timescale 1ns / 1ps

module float_unpacker (
    input  wire [31:0] float32,
    output wire        sign,
    output wire [7:0]  exponent,
    output wire [22:0] mantissa,
    output wire        is_zero,
    output wire        is_inf,
    output wire        is_nan,
    output wire        is_denormal
);

    assign sign     = float32[31];
    assign exponent = float32[30:23];
    assign mantissa = float32[22:0];

    // Classification Logic
    // Zero: Exponent and Mantissa are both all zeros
    assign is_zero     = (exponent == 8'h00) && (mantissa == 23'h0);
    
    // Denormal: Exponent is zero, but Mantissa is non-zero
    assign is_denormal = (exponent == 8'h00) && (mantissa != 23'h0);

    // Infinity: Exponent is all ones (0xFF), Mantissa is all zeros
    assign is_inf      = (exponent == 8'hFF) && (mantissa == 23'h0);

    // NaN: Exponent is all ones (0xFF), Mantissa is non-zero
    assign is_nan      = (exponent == 8'hFF) && (mantissa != 23'h0);

endmodule
