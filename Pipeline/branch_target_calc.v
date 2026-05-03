`include "defines.vh"
`timescale 1ns / 1ps

module branch_target_calc (
    input  wire [31:0] pc,
    input  wire [31:0] imm32,
    input  wire [31:0] valA,
    input  wire [31:0] valB,
    input  wire [5:0]  opcode,
    input  wire        branch,
    input  wire        jump,
    
    output reg  [31:0] target,
    output reg         take_branch
);

    always @(*) begin
        target = 32'd0;
        take_branch = 1'b0;

        if (branch == 1'b1) begin
            target = pc + (imm32 << 2);
            case (opcode)
                `OP_BEQ:  take_branch = (valA == valB);
                `OP_BNE:  take_branch = (valA != valB);
                `OP_BLT:  take_branch = ($signed(valA) < $signed(valB));
                `OP_BGT:  take_branch = ($signed(valA) > $signed(valB));
                `OP_BLE:  take_branch = ($signed(valA) <= $signed(valB));
                `OP_BGE:  take_branch = ($signed(valA) >= $signed(valB));
                `OP_BLTU: take_branch = (valA < valB);
                `OP_BGEU: take_branch = (valA >= valB);
                default:  take_branch = 1'b0;
            endcase
        end else if (jump == 1'b1) begin
            if (opcode == `OP_JAL || opcode == `OP_CALL) begin
                target = pc + (imm32 << 2);
                take_branch = 1'b1;
            end else if (opcode == `OP_JALR || opcode == `OP_RET || opcode == `OP_RETI) begin
                target = valA; // Jump to register
                take_branch = 1'b1;
            end
        end
    end

endmodule
