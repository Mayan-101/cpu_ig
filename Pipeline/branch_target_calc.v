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
        take_branch = 0;
        target = 32'h00000000;
        
        if (jump) begin
            take_branch = 1;
            if (opcode == 6'h38 || opcode == 6'h3A) begin // JAL, CALL
                // target = {pc[31:28], imm32[27:0]}
                // imm32 is already shifted left by 2 by imm_extender (MODE_JUMP outputs {4'b0, instr_bits[25:0], 2'b00})
                target = {pc[31:28], imm32[27:0]};
            end else if (opcode == 6'h39) begin // JALR
                target = valA + imm32;
            end
        end else if (branch) begin
            // PC in ID/EX is PC+4
            // Branch Target = PC+4 + (imm14_sext << 2)
            // Wait, imm_extender for Branch (MODE_SIGN) does NOT shift.
            // So we must shift here!
            target = pc + {imm32[29:0], 2'b00};
            
            case (opcode)
                6'h30: take_branch = (valA == valB);                 // BEQ
                6'h31: take_branch = (valA != valB);                 // BNE
                6'h32: take_branch = ($signed(valA) < $signed(valB)); // BLT
                6'h33: take_branch = ($signed(valA) > $signed(valB)); // BGT
                6'h34: take_branch = ($signed(valA) <= $signed(valB));// BLE
                6'h35: take_branch = ($signed(valA) >= $signed(valB));// BGE
                6'h36: take_branch = (valA < valB);                  // BLTU
                6'h37: take_branch = (valA >= valB);                 // BGEU
                default: take_branch = 0;
            endcase
        end
    end

endmodule
