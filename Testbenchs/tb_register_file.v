`timescale 1ns / 1ps

module tb_register_file();

    reg clk;
    reg rst;
    reg [4:0] rs1_addr;
    reg [4:0] rs2_addr;
    reg [4:0] rd_addr;
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
        rd_addr = 5'd3;
        wr_data = 32'h000000B0;
        we = 1;

        @(negedge clk);
        rd_addr = 5'd11;
        wr_data = 32'h000000B1;
        we = 1;

        @(negedge clk);
        we = 0;

        // Verify reads
        rs1_addr = 5'd3;
        rs2_addr = 5'd11;
        #1;
        if (rs1_data !== 32'h000000B0) 
            $display("FAIL: Test 1 (Read R3) expected 000000B0, got %h", rs1_data);
        else 
            $display("PASS: Test 1 (Read R3 is correct)");

        if (rs2_data !== 32'h000000B1) 
            $display("FAIL: Test 2 (Read R11) expected 000000B1, got %h", rs2_data);
        else 
            $display("PASS: Test 2 (Read R11 is correct)");

        // Test 2: Internal Forwarding (Write-before-Read)
        @(negedge clk);
        rd_addr = 5'd7;
        wr_data = 32'h12345678;
        we = 1;
        rs1_addr = 5'd7; // Reading same register being written
        #1;
        if (rs1_data !== 32'h12345678)
            $display("FAIL: Test 3 (Internal Forwarding) expected 12345678, got %h", rs1_data);
        else
            $display("PASS: Test 3 (Internal Forwarding is correct)");

        @(negedge clk);
        we = 0;

        // Test 3: R0 is hardwired to 0
        @(negedge clk);
        rd_addr = 5'd0;
        wr_data = 32'hFFFFFFFF;
        we = 1;

        @(negedge clk);
        we = 0;
        rs1_addr = 5'd0;
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
