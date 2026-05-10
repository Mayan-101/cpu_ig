`include "defines.vh"
`timescale 1ns / 1ps

/*
 * Module: imm_extender
 * Description: Extracts and sign-extends immediates from RISC-V instruction
 *              formats (I, S, B, U, J). Output is a 32-bit sign-extended value.
 *
 * ext_mode encoding:
 *   3'b000 = I-type  (ADDI, LW, JALR, etc.)
 *   3'b001 = S-type  (SW, SH, SB)
 *   3'b010 = B-type  (BEQ, BNE, BLT, BGE, etc.)
 *   3'b011 = U-type  (LUI, AUIPC)
 *   3'b100 = J-type  (JAL)
 */
module imm_extender (
    input  wire [31:7] instr,      // Instruction bits [31:7] (25 bits)
    input  wire [2:0]  ext_mode,
    output reg  [31:0] imm32
);

    always @(*) begin
        case (ext_mode)
            // I-type: imm[11:0] = instr[31:20], sign-extended
            3'b000: imm32 = {{20{instr[31]}}, instr[31:20]};

            // S-type: imm[11:5]=instr[31:25], imm[4:0]=instr[11:7], sign-extended
            3'b001: imm32 = {{20{instr[31]}}, instr[31:25], instr[11:7]};

            // B-type: imm[12|10:5]=instr[31:25], imm[4:1|11]=instr[11:7]
            // Reconstructed: {imm[12], imm[11], imm[10:5], imm[4:1], 0}
            3'b010: imm32 = {{19{instr[31]}}, instr[31], instr[7],
                             instr[30:25], instr[11:8], 1'b0};

            // U-type: imm[31:12] = instr[31:12], lower 12 bits = 0
            3'b011: imm32 = {instr[31:12], 12'b0};

            // J-type: imm[20|10:1|11|19:12] from instr[31:12]
            // Reconstructed: {imm[20], imm[19:12], imm[11], imm[10:1], 0}
            3'b100: imm32 = {{11{instr[31]}}, instr[31], instr[19:12],
                             instr[20], instr[30:21], 1'b0};

            default: imm32 = 32'd0;
        endcase
    end

endmodule
