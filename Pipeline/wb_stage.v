`include "defines.vh"
`timescale 1ns / 1ps

module wb_stage (
    // MEM/WB Pipeline Register Inputs
    input  wire [31:0] mem_wb_alu_result,
    input  wire [31:0] mem_wb_mem_data,
    input  wire [4:0]  mem_wb_rd_addr,
    input  wire         mem_wb_reg_write,
    input  wire [1:0]  mem_wb_wb_src,
    input  wire [31:0] mem_wb_pc_plus4,

    // I/O and CSR Inputs
    input  wire [31:0] ext_data_in,

    // Register File Write-Back Outputs
    output wire [4:0]  rf_wr_addr,
    output wire [31:0] rf_wr_data,
    output wire        rf_we
);

    assign rf_wr_addr = mem_wb_rd_addr;
    assign rf_we      = mem_wb_reg_write;

    assign rf_wr_data = (mem_wb_wb_src == 2'b01) ? mem_wb_mem_data :
                        (mem_wb_wb_src == 2'b10) ? mem_wb_pc_plus4 :
                        (mem_wb_wb_src == 2'b11) ? ext_data_in :
                        mem_wb_alu_result; // Default ALU (00)

endmodule

