`timescale 1ns / 1ps

module tb_mem_stage;

    reg clk;
    reg rst;
    
    reg [31:0] ex_mem_alu_result;
    reg ex_mem_zero;
    reg [31:0] ex_mem_wr_data;
    reg [5:0]  ex_mem_rd_addr;
    
    reg ex_mem_mem_read;
    reg ex_mem_mem_write;
    reg ex_mem_reg_write;
    reg ex_mem_is_io;
    reg [1:0] ex_mem_wb_src;
    
    reg [31:0] dcache_data;
    reg dcache_hit;
    
    wire [31:0] dcache_addr;
    wire [31:0] dcache_wr_data;
    wire dcache_we;
    wire dcache_re;
    wire cache_stall;
    
    wire [31:0] mem_wb_alu_result;
    wire [31:0] mem_wb_mem_data;
    wire [5:0]  mem_wb_rd_addr;
    wire mem_wb_reg_write;
    wire [1:0]  mem_wb_wb_src;
    wire mem_wb_is_io;

    mem_stage dut (
        .clk(clk),
        .rst(rst),
        .ex_mem_alu_result(ex_mem_alu_result),
        .ex_mem_zero(ex_mem_zero),
        .ex_mem_wr_data(ex_mem_wr_data),
        .ex_mem_rd_addr(ex_mem_rd_addr),
        .ex_mem_mem_read(ex_mem_mem_read),
        .ex_mem_mem_write(ex_mem_mem_write),
        .ex_mem_reg_write(ex_mem_reg_write),
        .ex_mem_is_io(ex_mem_is_io),
        .ex_mem_wb_src(ex_mem_wb_src),
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
        .mem_wb_is_io(mem_wb_is_io)
    );

    always #5 clk = ~clk;

    initial begin
        $display("--- M9.8: MEM Stage Test ---");
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
        dcache_data = 0;
        dcache_hit = 1;
        
        #15;
        rst = 0;

        // Test 1: Load Hit
        @(negedge clk);
        ex_mem_alu_result = 32'h0000A000;
        ex_mem_mem_read = 1;
        ex_mem_reg_write = 1;
        ex_mem_wb_src = 2'b01; // MEM
        dcache_hit = 1;
        dcache_data = 32'hDEADBEEF;
        
        @(negedge clk);
        #1;
        $display("Load Hit: stall=%b, re=%b, data=%h", cache_stall, dcache_re, mem_wb_mem_data);
        if (cache_stall !== 0 || dcache_re !== 1 || mem_wb_mem_data !== 32'hDEADBEEF) $display("FAIL: Load Hit");
        ex_mem_mem_read = 0;

        // Test 2: Store Miss -> Stall
        @(negedge clk);
        ex_mem_alu_result = 32'h0000B000;
        ex_mem_wr_data = 32'hCAFE1234;
        ex_mem_mem_write = 1;
        dcache_hit = 0;
        
        @(negedge clk);
        #1;
        $display("Store Miss: stall=%b, we=%b, data=%h", cache_stall, dcache_we, dcache_wr_data);
        if (cache_stall !== 1 || dcache_we !== 1 || dcache_wr_data !== 32'hCAFE1234) $display("FAIL: Store Miss");
        
        // Recover Hit
        @(negedge clk);
        dcache_hit = 1;
        
        @(negedge clk);
        #1;
        $display("Store Hit Recovered: stall=%b", cache_stall);
        if (cache_stall !== 0) $display("FAIL: Store Hit Recov");
        ex_mem_mem_write = 0;

        // Test 3: Non-memory (ALU)
        @(negedge clk);
        ex_mem_alu_result = 32'h11112222;
        ex_mem_wb_src = 2'b00; // ALU
        ex_mem_mem_read = 0;
        ex_mem_mem_write = 0;
        dcache_hit = 0; // should NOT stall since it's not a memory op!
        
        @(negedge clk);
        #1;
        $display("ALU Op: stall=%b, re=%b, we=%b, out_alu=%h", cache_stall, dcache_re, dcache_we, mem_wb_alu_result);
        if (cache_stall !== 0 || dcache_re !== 0 || dcache_we !== 0 || mem_wb_alu_result !== 32'h11112222) $display("FAIL: ALU Op");

        $display("Test finished.");
        $finish;
    end

endmodule
