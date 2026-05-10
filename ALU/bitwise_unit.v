`timescale 1ns / 1ps

module bitwise_unit (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [2:0]  op,
    output reg  [31:0] result
);

    // Operation codes defined in the prompt
    localparam OP_AND  = 3'b000,
               OP_OR   = 3'b001,
               OP_XOR  = 3'b010;

    always @(*) begin
        case (op)
            OP_AND:  result = a & b;
            OP_OR:   result = a | b;
            OP_XOR:  result = a ^ b;
            default: result = 32'h0; // Safe default
        endcase
    end


endmodule
