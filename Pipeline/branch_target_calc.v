`include "defines.vh"
`timescale 1ns / 1ps

/**
 * Module: branch_target_calc
 * Description: Computes branch/jump targets per RISC-V spec.
 */
module branch_target_calc (
    input  wire [31:0] pc,       // PC+4 from pipeline
    input  wire [31:0] imm32,
    input  wire [31:0] valA,     // rs1 value
    input  wire [31:0] valB,     // rs2 value
    input  wire [31:0] mepc,     // From CSR unit for RETI
    input  wire [6:0]  opcode,
    input  wire [2:0]  funct3,
    input  wire        branch,
    input  wire        jump,
    input  wire        is_reti,

    output reg  [31:0] target,
    output reg         take_branch
);

    wire [31:0] this_pc = pc - 32'd4;

    always @(*) begin
        target = 32'd0;
        take_branch = 1'b0;

        if (branch == 1'b1) begin
            target = this_pc + imm32;
            case (funct3)
                `F3_BEQ:  take_branch = (valA == valB);
                `F3_BNE:  take_branch = (valA != valB);
                `F3_BLT:  take_branch = ($signed(valA) < $signed(valB));
                `F3_BGE:  take_branch = ($signed(valA) >= $signed(valB));
                `F3_BLTU: take_branch = (valA < valB);
                `F3_BGEU: take_branch = (valA >= valB);
                default:  take_branch = 1'b0;
            endcase
        end else if (jump == 1'b1) begin
            if (is_reti) begin
                target = mepc;
                take_branch = 1'b1;
            end else if (opcode == `OPC_JAL) begin
                target = this_pc + imm32;
                take_branch = 1'b1;
            end else if (opcode == `OPC_JALR) begin
                target = (valA + imm32) & 32'hFFFFFFFE;
                take_branch = 1'b1;
            end
        end
    end

endmodule
