`include "defines.vh"

/*
 * Module: csr_unit
 * Description: Manages RISC-V Control/Status Registers (mstatus, mtvec, mepc, mcause, etc.).
 *              Handles standard CSR instructions (CSRRW/RS/RC) and traps (ECALL, MRET).
 */
module csr_unit (
    input  wire        clk,
    input  wire        rst,
    input  wire        stall,

    // Instruction Info (from EX stage for standard CSR instructions)
    input  wire [6:0]  ex_opcode,
    input  wire [2:0]  ex_funct3,
    input  wire [11:0] ex_csr_addr,
    input  wire [31:0] ex_rs1_data,
    input  wire [4:0]  ex_imm5,

    // Trap/Interrupt Interface
    input  wire        irq,
    input  wire        ecall_in,
    input  wire        mret_in,
    input  wire [31:0] pc_epc,      // PC for synchronous exceptions (ecall)
    input  wire [31:0] pc_fec,      // PC for asynchronous interrupts (next instruction)

    // MMIO/External Write Port (Legacy Compatibility)
    input  wire        ext_we,
    input  wire [11:0] ext_addr,
    input  wire [31:0] ext_wdata,

    // CSR Read Data (sent back to WB stage)
    output reg  [31:0] csr_rdata,
    
    // CSR outputs for pipeline control
    output reg  [31:0] mtvec,
    output reg  [31:0] mepc,
    output reg  [31:0] mstatus,
    output wire        trap_taken,
    output wire [31:0] trap_pc
);

    // CSR Register Definitions
    reg [31:0] mcause;
    reg [31:0] mip, mie;

    // Internal wires for instruction decoding
    wire is_csr_instr = (ex_opcode == `OPC_SYSTEM) && (ex_funct3 != `F3_ECALL);
    wire [31:0] csr_op_data = ex_funct3[2] ? {27'b0, ex_imm5} : ex_rs1_data;

    // Trap Logic
    assign trap_taken = (irq && mstatus[3]) || ecall_in;
    assign trap_pc = mtvec;

    // CSR Read Mux
    always @(*) begin
        case (ex_csr_addr)
            12'h300: csr_rdata = mstatus;
            12'h304: csr_rdata = mie;
            12'h305: csr_rdata = mtvec;
            12'h341: csr_rdata = mepc;
            12'h342: csr_rdata = mcause;
            12'h344: csr_rdata = mip;
            default: csr_rdata = 32'd0;
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mstatus <= 32'h0000_0000;
            mtvec   <= 32'h0000_0000;
            mepc    <= 32'h0000_0000;
            mcause  <= 32'd0;
            mie     <= 32'd0;
            mip     <= 32'd0;
        end else if (!stall) begin
            // 1. Handle CSR Instructions
            if (is_csr_instr) begin
                case (ex_funct3[1:0])
                    2'b01: begin // CSRRW
                        case (ex_csr_addr)
                            12'h300: mstatus <= csr_op_data;
                            12'h304: mie     <= csr_op_data;
                            12'h305: mtvec   <= csr_op_data;
                            12'h341: mepc    <= csr_op_data;
                            12'h342: mcause  <= csr_op_data;
                        endcase
                    end
                    2'b10: begin // CSRRS
                        case (ex_csr_addr)
                            12'h300: mstatus <= mstatus | csr_op_data;
                            12'h304: mie     <= mie | csr_op_data;
                            12'h305: mtvec   <= mtvec | csr_op_data;
                            12'h341: mepc    <= mepc | csr_op_data;
                            12'h342: mcause  <= mcause | csr_op_data;
                        endcase
                    end
                    2'b11: begin // CSRRC
                        case (ex_csr_addr)
                            12'h300: mstatus <= mstatus & ~csr_op_data;
                            12'h304: mie     <= mie & ~csr_op_data;
                            12'h305: mtvec   <= mtvec & ~csr_op_data;
                            12'h341: mepc    <= mepc & ~csr_op_data;
                            12'h342: mcause  <= mcause & ~csr_op_data;
                        endcase
                    end
                endcase
            end
            
            // 1.5 External MMIO Write (Legacy)
            if (ext_we && !is_csr_instr) begin
                case (ext_addr)
                    12'h000: mtvec   <= ext_wdata; // mtvec at 0x8000_0000
                    12'h004: mstatus <= ext_wdata; // mstatus at 0x8000_0004
                    12'h008: mepc    <= ext_wdata; // mepc at 0x8000_0008
                    12'h00C: mcause  <= ext_wdata; // mcause at 0x8000_000C
                endcase
            end

            // Legacy SEI/CLI support
            if (ex_opcode == `OPC_CUSTOM0) begin
                if (ex_funct3 == `F3_SEI) mstatus[3] <= 1'b1;
                if (ex_funct3 == `F3_CLI) mstatus[3] <= 1'b0;
            end


            // 2. Handle Traps (ECALL or IRQ)
            if (trap_taken) begin
                mepc <= ecall_in ? pc_epc : pc_fec;
                mstatus[7] <= mstatus[3]; // MPIE = MIE
                mstatus[3] <= 1'b0;       // MIE = 0
                mcause <= ecall_in ? 32'd11 : 32'h8000_0007; // Machine ECALL or Timer IRQ
            end


            // 3. Handle MRET
            if (mret_in) begin
                mstatus[3] <= mstatus[7]; // MIE = MPIE
                mstatus[7] <= 1'b1;       // MPIE = 1
            end
        end
    end

endmodule

