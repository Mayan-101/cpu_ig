`include "defines.vh"
`timescale 1ns / 1ps

module imm_extender (
    input  wire [25:0] instr_bits,
    input  wire [1:0]  ext_mode, // 0: SIGN, 1: ZERO, 2: JUMP, 3: LUI
    output reg  [31:0] imm32
);

    always @(*) begin
        case (ext_mode)
            2'b00: imm32 = {{18{instr_bits[13]}}, instr_bits[13:0]}; // SIGN (14-bit)
            2'b01: imm32 = {18'd0, instr_bits[13:0]};               // ZERO (14-bit)
            2'b10: imm32 = {{6{instr_bits[25]}}, instr_bits[25:0]};  // JUMP (26-bit)
            2'b11: imm32 = {instr_bits[19:0], 12'd0};               // LUI (20-bit)
            default: imm32 = 32'd0;
        endcase
    end

endmodule
