`include "defines.vh"

/*
 * Module: control_unit
 * Description: Combinational control logic for RISC-V RV32I/M/F decode.
 *              Decodes 7-bit opcode, funct3, and funct7 into pipeline control signals.
 */
module control_unit (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,

    output reg        mem_read,
    output reg        mem_write,
    output reg        reg_write,
    output reg        branch,
    output reg        jump,
    output reg        is_float,
    output reg        is_io,
    output reg  [1:0] wb_src,    // 0: ALU, 1: MEM, 2: PC+4, 3: IO
    output reg        alu_src,   // 0: RS2, 1: IMM
    output reg  [2:0] ext_mode,  // 0: I, 1: S, 2: B, 3: U, 4: J
    output reg        is_reti,
    output reg        is_halt
);

    always @(*) begin
        // ---- Defaults ----
        mem_read  = 0;
        mem_write = 0;
        reg_write = 0;
        branch    = 0;
        jump      = 0;
        is_float  = 0;
        is_io     = 0;
        wb_src    = 2'b00;   // ALU result
        alu_src   = 0;       // RS2
        ext_mode  = 3'b000;  // I-type
        is_reti   = 0;
        is_halt   = 0;

        case (opcode)
            // --- R-type: register-register ALU (including RV32M) ---
            `OPC_OP: begin
                reg_write = 1;
            end

            // --- I-type: register-immediate ALU ---
            `OPC_OP_IMM: begin
                reg_write = 1;
                alu_src   = 1;
                ext_mode  = 3'b000; // I-type
            end

            // --- Load (LB, LH, LW, LBU, LHU) ---
            `OPC_LOAD: begin
                reg_write = 1;
                mem_read  = 1;
                alu_src   = 1;       // base + offset
                wb_src    = 2'b01;   // MEM
                ext_mode  = 3'b000;  // I-type
            end

            // --- Store (SB, SH, SW) ---
            `OPC_STORE: begin
                mem_write = 1;
                alu_src   = 1;       // base + offset
                ext_mode  = 3'b001;  // S-type
            end

            // --- Branch ---
            `OPC_BRANCH: begin
                branch    = 1;
                ext_mode  = 3'b010;  // B-type
            end

            // --- JAL ---
            `OPC_JAL: begin
                jump      = 1;
                reg_write = 1;
                wb_src    = 2'b10;   // PC+4
                ext_mode  = 3'b100;  // J-type
            end

            // --- JALR ---
            `OPC_JALR: begin
                jump      = 1;
                reg_write = 1;
                alu_src   = 1;
                wb_src    = 2'b10;   // PC+4
                ext_mode  = 3'b000;  // I-type
            end

            // --- LUI ---
            `OPC_LUI: begin
                reg_write = 1;
                alu_src   = 1;
                ext_mode  = 3'b011;  // U-type
            end

            // --- AUIPC ---
            `OPC_AUIPC: begin
                reg_write = 1;
                alu_src   = 1;
                ext_mode  = 3'b011;  // U-type
            end

            // --- Floating Point ---
            `OPC_OP_FP: begin
                is_float  = 1;
                reg_write = (funct7 != `F7_FCMP); // FCMP only sets flags
            end

            // --- Custom-0: HLT, SEI, CLI, RETI, IN, OUT ---
            `OPC_CUSTOM0: begin
                case (funct3)
                    `F3_HLT:  is_halt = 1;
                    `F3_SEI:  ; // Handled in CSR unit
                    `F3_CLI:  ; // Handled in CSR unit
                    `F3_RETI: begin
                        is_reti = 1;
                        jump    = 1;
                    end
                    `F3_IN: begin
                        is_io     = 1;
                        reg_write = 1;
                        alu_src   = 1;
                        wb_src    = 2'b11;   // IO data
                        ext_mode  = 3'b000;  // I-type
                    end
                    `F3_OUT: begin
                        is_io     = 1;
                        alu_src   = 1;
                        ext_mode  = 3'b001;  // S-type (port in imm)
                    end
                    default: ;
                endcase
            end

            // --- SYSTEM (CSR, ECALL, MRET) ---
            `OPC_SYSTEM: begin
                if (funct3 == `F3_ECALL) begin
                    // ECALL or MRET
                    // funct7=0000000, rs2=00000, rs1=00000, funct3=000, rd=00000
                    // ECALL: imm=0x000, MRET: imm=0x302 (funct7=0x18, rs2=0x02)
                    if (funct7 == 7'b0011000) is_reti = 1; // MRET
                    else ; // ECALL handled in CSR unit
                end else begin
                    // CSR instructions
                    reg_write = 1;
                    wb_src    = 2'b11; // CSR data (reusing IO/CSR slot)
                end
            end


            default: ;
        endcase
    end

endmodule
