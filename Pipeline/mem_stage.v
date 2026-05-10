`include "defines.vh"
`timescale 1ns / 1ps

module mem_stage (
    input  wire clk,
    input  wire rst,

    // EX/MEM Pipeline Register Inputs
    input  wire [31:0] ex_mem_alu_result,
    input  wire ex_mem_zero,
    input  wire [31:0] ex_mem_wr_data,
    input  wire [4:0]  ex_mem_rd_addr,

    input  wire [31:0] ex_mem_pc_plus4,
    input  wire [31:0] ex_mem_ext_data,
    input  wire ex_mem_mem_read,

    input  wire ex_mem_mem_write,
    input  wire ex_mem_reg_write,
    input  wire ex_mem_is_io,
    input  wire [1:0] ex_mem_wb_src,
    input  wire [2:0] ex_mem_funct3,
    input  wire        ex_mem_is_halt,

    // D-Cache Interface
    input  wire [31:0] dcache_data,
    input  wire dcache_hit,
    output wire [31:0] dcache_addr,
    output wire [31:0] dcache_wr_data,
    output wire dcache_we,
    output wire dcache_re,

    // Hazard/Stall Control
    output wire cache_stall,

    // MEM/WB Pipeline Register Outputs
    output reg  [31:0] mem_wb_alu_result,
    output reg  [31:0] mem_wb_mem_data,
    output reg  [4:0]  mem_wb_rd_addr,
    output reg         mem_wb_reg_write,
    output reg  [1:0]  mem_wb_wb_src,
    output reg  [31:0] mem_wb_pc_plus4,
    output reg  [31:0] mem_wb_ext_data,
    output reg         mem_wb_is_io,
    output reg         mem_wb_is_halt
);


    assign dcache_addr    = ex_mem_alu_result;
    assign dcache_wr_data = ex_mem_wr_data;
    assign dcache_we      = ex_mem_mem_write;
    assign dcache_re      = ex_mem_mem_read;



    assign cache_stall = ((ex_mem_mem_read == 1'b1) || (ex_mem_mem_write == 1'b1)) && (dcache_hit == 1'b0);

    always @(posedge clk) begin
        if (rst) begin
            mem_wb_alu_result <= 0;
            mem_wb_mem_data   <= 0;
            mem_wb_rd_addr    <= 0;
            mem_wb_reg_write  <= 0;
            mem_wb_wb_src     <= 0;
            mem_wb_pc_plus4   <= 0;
            mem_wb_ext_data   <= 0;
            mem_wb_is_io      <= 0;
            mem_wb_is_halt    <= 0;
        end else if (!cache_stall) begin
            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_mem_data   <= dcache_data;
            mem_wb_rd_addr    <= ex_mem_rd_addr;
            mem_wb_reg_write  <= ex_mem_reg_write;
            mem_wb_wb_src     <= ex_mem_wb_src;
            mem_wb_pc_plus4   <= ex_mem_pc_plus4;
            mem_wb_ext_data   <= ex_mem_ext_data;
            mem_wb_is_io      <= ex_mem_is_io;
            mem_wb_is_halt    <= ex_mem_is_halt;
        end
    end

endmodule
