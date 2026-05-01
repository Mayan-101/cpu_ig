`timescale 1ns / 1ps

module float_packer (
    input  wire        sign,
    input  wire [7:0]  exponent,
    input  wire [22:0] mantissa,
    output wire [31:0] float32
);

    assign float32 = {sign, exponent, mantissa};

endmodule