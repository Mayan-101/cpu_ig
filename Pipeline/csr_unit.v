`include "defines.vh"

/*
 * Module: csr_unit
 * Description: Manages Control/Status Registers (PSW, mtvec, mepc, mstatus).
 *              Handles memory-mapped CSR writes, SEI/CLI (interrupt enable/disable),
 *              and interrupt entry (saves PC/PSW, clears MIE bit).
 */
module csr_unit (
    input  wire        clk,
    input  wire        rst,

    // Stall control (gate CSR updates during cache stalls)
    input  wire        stall,

    // Memory-mapped write port (from MEM stage)
    input  wire [31:0] dmem_addr,
    input  wire [31:0] dmem_wr_data,
    input  wire        dmem_we,

    // EI/DI from EX stage (MISC opcode + funct field)
    input  wire [5:0]  ex_alu_op,
    input  wire [7:0]  ex_funct,

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
            // Memory-mapped CSR writes
            if (dmem_we) begin
                if (dmem_addr == 32'h8000_0000) mtvec   <= dmem_wr_data;
                if (dmem_addr == 32'h8000_0004) mepc    <= dmem_wr_data;
                if (dmem_addr == 32'h8000_0008) mstatus <= dmem_wr_data;
            end
            // SEI/CLI: interrupt enable/disable via MISC funct
            if (ex_alu_op == `OP_MISC) begin
                if (ex_funct == `FUNCT_EI) psw[31] <= 1'b1;
                if (ex_funct == `FUNCT_DI) psw[31] <= 1'b0;
            end
            // Interrupt entry: save context and disable interrupts
            if (int_taken) begin
                mepc <= pc; mstatus <= psw; psw[31] <= 1'b0;
            end
        end
    end

endmodule
