`timescale 1ns / 1ps

module imm_extender (
    input  wire [25:0] instr_bits,
    input  wire [1:0]  ext_mode,
    output reg  [31:0] imm32
);

    localparam MODE_SIGN = 2'b00;
    localparam MODE_ZERO = 2'b01;
    localparam MODE_JUMP = 2'b10;
    localparam MODE_LUI  = 2'b11;

    always @(*) begin
        case (ext_mode)
            MODE_SIGN: imm32 = {{18{instr_bits[13]}}, instr_bits[13:0]};
            MODE_ZERO: imm32 = {18'b0, instr_bits[13:0]};
            MODE_JUMP: imm32 = {4'b0, instr_bits[25:0], 2'b00};
            MODE_LUI:  imm32 = {instr_bits[19:0], 12'b0};
            default:   imm32 = 32'b0;
        endcase
    end

endmodule
