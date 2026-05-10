`timescale 1ns / 1ps

module tb_wb_stage;

    reg [31:0] mem_wb_alu_result;
    reg [31:0] mem_wb_mem_data;
    reg [4:0]  mem_wb_rd_addr;
    reg        mem_wb_reg_write;
    reg [1:0]  mem_wb_wb_src;
    reg        mem_wb_is_io;
    reg [31:0] io_data_in;
    
    wire [4:0]  rf_wr_addr;
    wire [31:0] rf_wr_data;
    wire        rf_we;

    wb_stage dut (
        .mem_wb_alu_result(mem_wb_alu_result),
        .mem_wb_mem_data(mem_wb_mem_data),
        .mem_wb_rd_addr(mem_wb_rd_addr),
        .mem_wb_reg_write(mem_wb_reg_write),
        .mem_wb_wb_src(mem_wb_wb_src),
        .mem_wb_is_io(mem_wb_is_io),
        .io_data_in(io_data_in),
        .rf_wr_addr(rf_wr_addr),
        .rf_wr_data(rf_wr_data),
        .rf_we(rf_we)
    );

    initial begin
        $display("--- RISC-V Write Back Stage Test ---");
        mem_wb_alu_result = 32'h00000000;
        mem_wb_mem_data = 32'h00000000;
        mem_wb_rd_addr = 5'd0;
        mem_wb_reg_write = 0;
        mem_wb_wb_src = 2'b00;
        mem_wb_is_io = 0;
        io_data_in = 32'h00000000;
        
        // Test 1: ALU result
        #5;
        mem_wb_alu_result = 32'h12345678;
        mem_wb_rd_addr = 5'd5;
        mem_wb_reg_write = 1;
        mem_wb_wb_src = 2'b00; // ALU
        #1;
        $display("ALU Write: we=%b, addr=%d, data=%h", rf_we, rf_wr_addr, rf_wr_data);
        if (rf_we !== 1 || rf_wr_addr !== 5 || rf_wr_data !== 32'h12345678) $display("FAIL: ALU Write");

        // Test 2: MEM result
        #5;
        mem_wb_mem_data = 32'hDEADBEEF;
        mem_wb_wb_src = 2'b01; // MEM
        #1;
        $display("MEM Write: we=%b, addr=%d, data=%h", rf_we, rf_wr_addr, rf_wr_data);
        if (rf_we !== 1 || rf_wr_addr !== 5 || rf_wr_data !== 32'hDEADBEEF) $display("FAIL: MEM Write");

        // Test 3: I/O result
        #5;
        io_data_in = 32'h11223344;
        mem_wb_wb_src = 2'b11; // I/O
        #1;
        $display("I/O Write: we=%b, addr=%d, data=%h", rf_we, rf_wr_addr, rf_wr_data);
        if (rf_we !== 1 || rf_wr_addr !== 5 || rf_wr_data !== 32'h11223344) $display("FAIL: I/O Write");

        $display("Test finished.");
        $finish;
    end

endmodule
