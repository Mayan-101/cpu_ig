`timescale 1ns / 1ps

module tb_rom();

    reg clk;
    reg [9:0] addr;
    reg rd_en;
    wire [31:0] data;
    wire valid;

    // Instantiate ROM
    rom uut (
        .clk(clk),
        .addr(addr),
        .rd_en(rd_en),
        .data(data),
        .valid(valid)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test sequence
    initial begin
        // Initialize inputs
        addr = 0;
        rd_en = 0;

        // Wait a few cycles
        #15;

        // Test 1: Read address 0 (first instruction)
        @(negedge clk);
        addr = 10'd0;
        rd_en = 1;
        
        @(negedge clk);
        rd_en = 0;
        #1;
        if (valid !== 1'b1 || data !== 32'hAAAA_BBBB)
            $display("FAIL: Test 1 (Read addr 0) expected AAAA_BBBB, got %h (valid=%b)", data, valid);
        else
            $display("PASS: Test 1 (Read addr 0)");

        // Test 2: Read mid address (addr 500)
        @(negedge clk);
        addr = 10'd500;
        rd_en = 1;

        @(negedge clk);
        rd_en = 0;
        #1;
        if (valid !== 1'b1 || data !== 32'h1234_5678)
            $display("FAIL: Test 2 (Read addr 500) expected 1234_5678, got %h", data);
        else
            $display("PASS: Test 2 (Read addr 500)");

        // Test 3: Read address 1023 (last instruction)
        @(negedge clk);
        addr = 10'd1023;
        rd_en = 1;

        @(negedge clk);
        rd_en = 0;
        #1;
        if (valid !== 1'b1 || data !== 32'hDEAD_C0DE)
            $display("FAIL: Test 3 (Read addr 1023) expected DEAD_C0DE, got %h", data);
        else
            $display("PASS: Test 3 (Read addr 1023)");

        // Test 4: Write attempt (should not change output, valid should be 0 when rd_en is 0)
        @(negedge clk);
        addr = 10'd0; // Attempting to read with rd_en=0
        rd_en = 0;

        @(negedge clk);
        #1;
        if (valid !== 1'b0)
            $display("FAIL: Test 4 (rd_en=0) expected valid=0, got %b", valid);
        else
            $display("PASS: Test 4 (Write attempt / rd_en=0 correctly deasserts valid)");

        #10;
        $display("All ROM tests completed.");
        $finish;
    end

endmodule
