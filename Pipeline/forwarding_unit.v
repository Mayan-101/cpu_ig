`timescale 1ns / 1ps

/**
 * Forwarding Unit
 *
 * Generates MUX select signals for EX-EX and MEM-EX forwarding to resolve RAW hazards.
 * 5-bit register addresses for RISC-V (x0-x31).
 */
module forwarding_unit (
    input  wire [4:0] ex_mem_rd_addr,
    input  wire       ex_mem_reg_write,
    input  wire [4:0] mem_wb_rd_addr,
    input  wire       mem_wb_reg_write,
    input  wire [4:0] id_ex_rs1_addr,
    input  wire [4:0] id_ex_rs2_addr,
    output reg  [1:0] forwardA,
    output reg  [1:0] forwardB
);

    always @(*) begin
        // Forwarding for Source A
        if (ex_mem_reg_write && (ex_mem_rd_addr != 5'd0) && (ex_mem_rd_addr == id_ex_rs1_addr))
            forwardA = 2'b10;
        else if (mem_wb_reg_write && (mem_wb_rd_addr != 5'd0) && (mem_wb_rd_addr == id_ex_rs1_addr))
            forwardA = 2'b01;
        else
            forwardA = 2'b00;

        // Forwarding for Source B
        if (ex_mem_reg_write && (ex_mem_rd_addr != 5'd0) && (ex_mem_rd_addr == id_ex_rs2_addr))
            forwardB = 2'b10;
        else if (mem_wb_reg_write && (mem_wb_rd_addr != 5'd0) && (mem_wb_rd_addr == id_ex_rs2_addr))
            forwardB = 2'b01;
        else
            forwardB = 2'b00;
    end

endmodule
