`timescale 1ns / 1ps

module tb_reg32();

    reg clk;
    reg rst;
    reg we;
    reg [31:0] d;
    wire [31:0] q;

    // Instantiate the module under test (MUT)
    reg32 uut (
        .clk(clk),
        .rst(rst),
        .we(we),
        .d(d),
        .q(q)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period (100MHz)
    end

    // Test sequence
    initial begin
        // Initialize inputs
        rst = 1;
        we = 0;
        d = 32'h0;

        // Apply reset
        #15;
        rst = 0;
        
        // Test 1: Write and read
        @(negedge clk);
        d = 32'hDEADBEEF;
        we = 1;
        @(negedge clk);
        we = 0; // stop writing
        
        if (q !== 32'hDEADBEEF) $display("FAIL: Test 1 (Write) expected DEADBEEF, got %h", q);
        else $display("PASS: Test 1 (Write)");

        // Test 2: No-write hold
        @(negedge clk);
        d = 32'hCAFEBABE; // change d while we=0
        @(negedge clk);
        
        if (q !== 32'hDEADBEEF) $display("FAIL: Test 2 (No-write hold) expected DEADBEEF, got %h", q);
        else $display("PASS: Test 2 (No-write hold)");

        // Test 3: Synchronous reset -> 0
        @(negedge clk);
        rst = 1;
        @(negedge clk);
        
        if (q !== 32'd0) $display("FAIL: Test 3 (Sync reset) expected 0, got %h", q);
        else $display("PASS: Test 3 (Sync reset)");

        #10;
        $display("All reg32 tests completed.");
        $finish;
    end

endmodule
