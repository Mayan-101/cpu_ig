`timescale 1ns / 1ps

module tb_pipeline_reg();

    reg clk;
    reg rst;
    reg stall;
    reg flush;
    reg [31:0] data_in;
    wire [31:0] data_out;

    pipeline_reg #(.WIDTH(32)) uut (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .flush(flush),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        // Initialize
        rst = 1; stall = 0; flush = 0; data_in = 32'hAAAAAAAA;
        #15 rst = 0;

        // Test 1: Normal operation
        data_in = 32'h12345678;
        @(posedge clk);
        #1;
        if (data_out === 32'h12345678)
            $display("PASS: Test 1 (Normal) data_out=12345678");
        else
            $display("FAIL: Test 1 (Normal) data_out=%h", data_out);

        // Test 2: Stall
        stall = 1;
        data_in = 32'hDEADBEEF;
        @(posedge clk);
        #1;
        if (data_out === 32'h12345678)
            $display("PASS: Test 2 (Stall) data_out holds 12345678");
        else
            $display("FAIL: Test 2 (Stall) data_out=%h", data_out);

        // Test 3: Resume
        stall = 0;
        @(posedge clk);
        #1;
        if (data_out === 32'hDEADBEEF)
            $display("PASS: Test 3 (Resume) data_out=DEADBEEF");
        else
            $display("FAIL: Test 3 (Resume) data_out=%h", data_out);

        // Test 4: Flush
        flush = 1;
        data_in = 32'hCAFEBABE;
        @(posedge clk);
        #1;
        if (data_out === 0)
            $display("PASS: Test 4 (Flush) data_out=0");
        else
            $display("FAIL: Test 4 (Flush) data_out=%h", data_out);

        // Test 5: Release Flush
        flush = 0;
        @(posedge clk);
        #1;
        if (data_out === 32'hCAFEBABE)
            $display("PASS: Test 5 (Release Flush) data_out=CAFEBABE");
        else
            $display("FAIL: Test 5 (Release Flush) data_out=%h", data_out);

        $display("Pipeline Register Test completed.");
        $finish;
    end

endmodule
