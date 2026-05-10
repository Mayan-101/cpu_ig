`include "defines.vh"

/*
 * Module: csr_unit
 * Description: Manages Control/Status Registers (PSW, mtvec, mepc, mstatus).
 *              Handles memory-mapped CSR writes, SEI/CLI (interrupt enable/disable),
 *              and interrupt entry (saves PC/PSW, clears MIE bit).
 *              Updated for RISC-V custom-0 opcode encoding.
 */
module csr_unit (
    input  wire        clk,
    input  wire        rst,

    // Stall control (gate CSR updates during cache stalls)
    input  wire        stall,

    // Dedicated CSR write port (from MEM stage)
    input  wire [31:0] csr_addr,
    input  wire [31:0] csr_wr_data,
    input  wire        csr_we,

    // EI/DI from EX stage (custom-0 opcode + funct3)
    input  wire [6:0]  ex_opcode,
    input  wire [2:0]  ex_funct3,

    // Interrupt interface
    input  wire        irq,
    input  wire [31:0] pc,

    // CSR outputs
    output reg  [31:0] psw,
    output reg  [31:0] mtvec,
    output reg  [31:0] mepc,
    output reg  [31:0] mstatus,
    output wire        int_taken
);


    assign int_taken = (irq == 1'b1) && (psw[31] == 1'b1);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            psw     <= 32'd0;
            mtvec   <= 32'h0000_0000;
            mepc    <= 32'h0000_0000;
            mstatus <= 32'h0000_0000;
        end else if (!stall) begin
            // Dedicated CSR writes
            if (csr_we) begin
                if (csr_addr == 32'h8000_0000) mtvec   <= csr_wr_data;
                if (csr_addr == 32'h8000_0004) mepc    <= csr_wr_data;
                if (csr_addr == 32'h8000_0008) mstatus <= csr_wr_data;
            end

            // SEI/CLI: interrupt enable/disable via CUSTOM-0 opcode
            if (ex_opcode == `OPC_CUSTOM0) begin
                if (ex_funct3 == `F3_SEI) psw[31] <= 1'b1;
                if (ex_funct3 == `F3_CLI) psw[31] <= 1'b0;
            end
            // Interrupt entry: save context and disable interrupts
            if (int_taken) begin
                mepc <= pc; mstatus <= psw; psw[31] <= 1'b0;
            end
        end
    end

endmodule
