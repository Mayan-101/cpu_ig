`timescale 1ns / 1ps

module tb_register_file();

    reg clk;
    reg rst;
    reg [5:0] rs1_addr;
    reg [5:0] rs2_addr;
    reg [5:0] rd_addr;
    reg [31:0] wr_data;
    reg we;
    
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;

    // Instantiate the module under test (MUT)
    register_file uut (
        .clk(clk),
        .rst(rst),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr(rd_addr),
        .wr_data(wr_data),
        .we(we),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period
    end

    // Test sequence
    initial begin
        // Initialize inputs
        rst = 1;
        rs1_addr = 0;
        rs2_addr = 0;
        rd_addr = 0;
        wr_data = 0;
        we = 0;

        // Apply reset
        #15;
        rst = 0;

        // Test 1: Write R3, read R3
        @(negedge clk);
        rd_addr = 6'd3;
        wr_data = 32'h000000B0;
        we = 1;

        @(negedge clk);
        rd_addr = 6'd11;
        wr_data = 32'h000000B1;
        we = 1;

        @(negedge clk);
        we = 0;

        // Verify reads
        rs1_addr = 6'd3;
        rs2_addr = 6'd11;
        #1;
        if (rs1_data !== 32'h000000B0) 
            $display("FAIL: Test 1 (Read R3) expected 000000B0, got %h", rs1_data);
        else 
            $display("PASS: Test 1 (Read R3 is correct)");

        if (rs2_data !== 32'h000000B1) 
            $display("FAIL: Test 2 (Read R11) expected 000000B1, got %h", rs2_data);
        else 
            $display("PASS: Test 2 (Read R11 is correct)");

        // Test 3: Read and Write ACC (addr=32) and B (addr=33)
        @(negedge clk);
        rd_addr = 6'd32; // ACC
        wr_data = 32'hAAAAAAAA;
        we = 1;

        @(negedge clk);
        rd_addr = 6'd33; // B
        wr_data = 32'hBBBBBBBB;
        we = 1;

        @(negedge clk);
        we = 0;

        // Verify ACC and B
        rs1_addr = 6'd32;
        rs2_addr = 6'd33;
        #1;
        if (rs1_data !== 32'hAAAAAAAA || rs2_data !== 32'hBBBBBBBB)
            $display("FAIL: Test 3 (ACC and B) ACC=%h, B=%h", rs1_data, rs2_data);
        else
            $display("PASS: Test 3 (ACC and B read/write is correct)");

        // Test 4: R0 is hardwired to 0
        @(negedge clk);
        rd_addr = 6'd0;
        wr_data = 32'hFFFFFFFF;
        we = 1;

        @(negedge clk);
        we = 0;
        rs1_addr = 6'd0;
        #1;
        if (rs1_data !== 32'd0)
            $display("FAIL: Test 4 (R0 write test) expected 0, got %h", rs1_data);
        else
            $display("PASS: Test 4 (R0 is hardwired to 0)");

        #10;
        $display("All register_file tests completed.");
        $finish;
    end

endmodule
