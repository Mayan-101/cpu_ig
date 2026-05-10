`include "defines.vh"
`timescale 1ns / 1ps

module tb_mem_stage;

    reg clk;
    reg rst;
    
    reg [31:0] ex_mem_alu_result;
    reg ex_mem_zero;
    reg [31:0] ex_mem_wr_data;
    reg [4:0]  ex_mem_rd_addr;
    
    reg [31:0] ex_mem_pc_plus4;
    reg [31:0] ex_mem_ext_data;
    
    reg ex_mem_mem_read;
    reg ex_mem_mem_write;
    reg ex_mem_reg_write;
    reg ex_mem_is_io;
    reg [1:0] ex_mem_wb_src;
    reg [2:0] ex_mem_funct3;
    reg       ex_mem_is_halt;
    
    reg [31:0] dcache_data;
    reg dcache_hit;
    
    wire [31:0] dcache_addr;
    wire [31:0] dcache_wr_data;
    wire dcache_we;
    wire dcache_re;
    wire cache_stall;
    
    wire [31:0] mem_wb_alu_result;
    wire [31:0] mem_wb_mem_data;
    wire [4:0]  mem_wb_rd_addr;
    wire mem_wb_reg_write;
    wire [1:0]  mem_wb_wb_src;
    wire [31:0] mem_wb_pc_plus4;
    wire [31:0] mem_wb_ext_data;
    wire mem_wb_is_io;
    wire mem_wb_is_halt;

    mem_stage dut (
        .clk(clk),
        .rst(rst),
        .ex_mem_alu_result(ex_mem_alu_result),
        .ex_mem_zero(ex_mem_zero),
        .ex_mem_wr_data(ex_mem_wr_data),
        .ex_mem_rd_addr(ex_mem_rd_addr),
        .ex_mem_pc_plus4(ex_mem_pc_plus4),
        .ex_mem_ext_data(ex_mem_ext_data),
        .ex_mem_mem_read(ex_mem_mem_read),
        .ex_mem_mem_write(ex_mem_mem_write),
        .ex_mem_reg_write(ex_mem_reg_write),
        .ex_mem_is_io(ex_mem_is_io),
        .ex_mem_wb_src(ex_mem_wb_src),
        .ex_mem_funct3(ex_mem_funct3),
        .ex_mem_is_halt(ex_mem_is_halt),
        .dcache_data(dcache_data),
        .dcache_hit(dcache_hit),
        .dcache_addr(dcache_addr),
        .dcache_wr_data(dcache_wr_data),
        .dcache_we(dcache_we),
        .dcache_re(dcache_re),
        .cache_stall(cache_stall),
        .mem_wb_alu_result(mem_wb_alu_result),
        .mem_wb_mem_data(mem_wb_mem_data),
        .mem_wb_rd_addr(mem_wb_rd_addr),
        .mem_wb_reg_write(mem_wb_reg_write),
        .mem_wb_wb_src(mem_wb_wb_src),
        .mem_wb_pc_plus4(mem_wb_pc_plus4),
        .mem_wb_ext_data(mem_wb_ext_data),
        .mem_wb_is_io(mem_wb_is_io),
        .mem_wb_is_halt(mem_wb_is_halt)
    );


    always #5 clk = ~clk;

    initial begin
        $display("--- RISC-V MEM Stage Test ---");
        clk = 0;
        rst = 1;
        ex_mem_alu_result = 0;
        ex_mem_zero = 0;
        ex_mem_wr_data = 0;
        ex_mem_rd_addr = 0;
        ex_mem_mem_read = 0;
        ex_mem_mem_write = 0;
        ex_mem_reg_write = 0;
        ex_mem_is_io = 0;
        ex_mem_wb_src = 0;
        ex_mem_funct3 = 0;
        ex_mem_is_halt = 0;
        dcache_data = 0;
        dcache_hit = 1;
        
        #15;
        rst = 0;

        // Test 1: Load LW Hit
        @(negedge clk);
        ex_mem_alu_result = 32'h0000A000;
        ex_mem_mem_read = 1;
        ex_mem_reg_write = 1;
        ex_mem_wb_src = 2'b01; // MEM
        ex_mem_funct3 = `F3_LW;
        dcache_hit = 1;
        dcache_data = 32'hDEADBEEF;
        
        @(negedge clk);
        #1;
        $display("LW Hit: stall=%b, re=%b, data=%h", cache_stall, dcache_re, mem_wb_mem_data);
        if (cache_stall !== 0 || dcache_re !== 1 || mem_wb_mem_data !== 32'hDEADBEEF) $display("FAIL: LW Hit");
        ex_mem_mem_read = 0;

        // Test 2: Store SW Miss -> Stall
        @(negedge clk);
        ex_mem_alu_result = 32'h0000B000;
        ex_mem_wr_data = 32'hCAFE1234;
        ex_mem_mem_write = 1;
        ex_mem_funct3 = `F3_SW;
        dcache_hit = 0;
        
        @(negedge clk);
        #1;
        $display("SW Miss: stall=%b, we=%b", cache_stall, dcache_we);
        if (cache_stall !== 1 || dcache_we !== 1) $display("FAIL: SW Miss stall");
        
        // Recover Hit
        @(negedge clk);
        dcache_hit = 1;
        
        @(negedge clk);
        #1;
        $display("SW Hit Recovered: stall=%b", cache_stall);
        if (cache_stall !== 0) $display("FAIL: SW Hit Recov");
        ex_mem_mem_write = 0;

        $display("Test finished.");
        $finish;
    end

endmodule
