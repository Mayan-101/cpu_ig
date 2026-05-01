`timescale 1ns / 1ps

module wb_stage (
    // MEM/WB Pipeline Register Inputs
    input  wire [31:0] mem_wb_alu_result,
    input  wire [31:0] mem_wb_mem_data,
    input  wire [5:0]  mem_wb_rd_addr,
    input  wire        mem_wb_reg_write,
    input  wire [1:0]  mem_wb_wb_src,
    input  wire        mem_wb_is_io,
    
    // External I/O Data (if applicable)
    input  wire [31:0] io_data_in,
    
    // PC+4 (Passed through pipeline for JAL/CALL, if we supported it in WB, 
    // but in this architecture, JAL stores to ACC, which is handled elsewhere or via standard GPRs. 
    // For now we assume wb_src=2 is unused or handled specially. We'll add PC+4 if needed later).
    
    // Outputs to Register File
    output wire [5:0]  rf_wr_addr,
    output wire [31:0] rf_wr_data,
    output wire        rf_we
);

    assign rf_wr_addr = mem_wb_rd_addr;
    
    assign rf_we = mem_wb_reg_write;
    
    assign rf_wr_data = (mem_wb_wb_src == 2'b01) ? mem_wb_mem_data :
                        (mem_wb_wb_src == 2'b11) ? io_data_in :
                        mem_wb_alu_result; // Default ALU

endmodule
