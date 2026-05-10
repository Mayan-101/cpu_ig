`timescale 1ns / 1ps

module tb_itcm;
    reg clk;
    reg [11:0] addr_a, addr_b;
    reg [31:0] din_a;
    reg we_a;
    wire [31:0] dout_a, dout_b;

    // Instantiate UUT
    itcm uut (
        .clk(clk),
        .addr_a(addr_a),
        .din_a(din_a),
        .we_a(we_a),
        .dout_a(dout_a),
        .addr_b(addr_b),
        .dout_b(dout_b)
    );

    // Clock
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        addr_a = 0;
        addr_b = 0;
        din_a = 0;
        we_a = 0;

        $display("--- ITCM Unit Test ---");

        // Test 1: Write to Port A, Read from Port A
        #10;
        @(negedge clk);
        addr_a = 14'h0001;
        din_a = 32'hDEADBEEF;
        we_a = 1;
        #10;
        we_a = 0;
        @(negedge clk);
        if (dout_a === 32'hDEADBEEF) $display("PASS: Port A Read/Write");
        else $display("FAIL: Port A Read/Write (Got %h)", dout_a);

        // Test 2: Read from Port B (Instruction Fetch)
        addr_b = 14'h0001;
        #5; // Asynch read
        if (dout_b === 32'hDEADBEEF) $display("PASS: Port B Instruction Fetch");
        else $display("FAIL: Port B Instruction Fetch (Got %h)", dout_b);

        // Test 3: Simultaneous access
        @(negedge clk);
        addr_a = 14'h0002;
        din_a = 32'hCAFEBABE;
        we_a = 1;
        addr_b = 14'h0001; // Should still see DEADBEEF
        #5;
        if (dout_b === 32'hDEADBEEF) $display("PASS: Simultaneous Port B Read");
        else $display("FAIL: Simultaneous Port B Read");
        
        #5;
        we_a = 0;
        @(negedge clk);
        addr_a = 14'h0002;
        #5;
        if (dout_a === 32'hCAFEBABE) $display("PASS: Port A Simultaneous Write Verification");

        $display("ITCM Test Completed.");
        $finish;
    end
endmodule
