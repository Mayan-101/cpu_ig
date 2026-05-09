`timescale 1ns / 1ps

module tb_dtcm;
    reg clk;
    reg [13:0] addr;
    reg [31:0] din;
    reg we;
    wire [31:0] dout;

    // Instantiate UUT
    dtcm uut (
        .clk(clk),
        .addr(addr),
        .din(din),
        .we(we),
        .dout(dout)
    );

    // Clock
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        addr = 0;
        din = 0;
        we = 0;

        $display("--- DTCM Unit Test ---");

        // Test 1: Basic Write/Read
        #10;
        @(negedge clk);
        addr = 14'h03FF;
        din = 32'h12345678;
        we = 1;
        #10;
        we = 0;
        @(negedge clk);
        if (dout === 32'h12345678) $display("PASS: DTCM Read/Write");
        else $display("FAIL: DTCM Read/Write (Got %h)", dout);

        // Test 2: Overwrite
        @(negedge clk);
        din = 32'h87654321;
        we = 1;
        #10;
        we = 0;
        @(negedge clk);
        if (dout === 32'h87654321) $display("PASS: DTCM Overwrite");
        else $display("FAIL: DTCM Overwrite");

        $display("DTCM Test Completed.");
        $finish;
    end
endmodule
