`timescale 1ns / 1ps

module tb_wt_controller;

    reg clk;
    reg rst;
    
    reg cache_hit;
    reg we;
    reg [31:0] addr;
    reg [31:0] data;
    wire wt_pending;
    
    reg mem_ready;
    wire mem_we;
    wire [31:0] mem_addr;
    wire [31:0] mem_data;

    wt_controller dut (
        .clk(clk),
        .rst(rst),
        .cache_hit(cache_hit),
        .we(we),
        .addr(addr),
        .data(data),
        .wt_pending(wt_pending),
        .mem_ready(mem_ready),
        .mem_we(mem_we),
        .mem_addr(mem_addr),
        .mem_data(mem_data)
    );

    always #5 clk = ~clk;

    initial begin
        $display("---8: Write-Through Controller Test ---");
        clk = 0;
        rst = 1;
        cache_hit = 0;
        we = 0;
        addr = 0;
        data = 0;
        mem_ready = 0;
        
        #15;
        rst = 0;
        
        // Test 1: Hit + write -> mem_we=1 with correct addr/data.
        @(negedge clk);
        cache_hit = 1;
        we = 1;
        addr = 32'h000000A0;
        data = 32'h11111111;
        #1;
        $display("Write 1: mem_we=%b mem_addr=%h mem_data=%h", mem_we, mem_addr, mem_data);
        if (mem_we !== 1 || mem_addr !== 32'h000000A0 || mem_data !== 32'h11111111) $display("FAIL: Write 1 passthrough failed");
        
        @(negedge clk);
        we = 0;
        #1;
        $display("Cycle 2: wt_pending=%b, mem_we=%b mem_addr=%h", wt_pending, mem_we, mem_addr);
        if (wt_pending !== 1 || mem_we !== 1 || mem_addr !== 32'h000000A0) $display("FAIL: Write 1 buffer failed");
        
        // Test 2: Two consecutive writes
        @(negedge clk);
        cache_hit = 1;
        we = 1;
        addr = 32'h000000B0;
        data = 32'h22222222;
        #1;
        $display("Write 2 initiated while pending=%b", wt_pending);
        if (wt_pending !== 1) $display("FAIL: Expected pending=1 to stall cache");
        
        mem_ready = 1;
        @(negedge clk);
        mem_ready = 0;
        #1;
        $display("After mem_ready, wt_pending=%b, mem_we=%b mem_addr=%h", wt_pending, mem_we, mem_addr);
        if (mem_we !== 1 || mem_addr !== 32'h000000B0) $display("FAIL: Write 2 not passed through");
        
        @(negedge clk);
        we = 0;
        mem_ready = 1;
        @(negedge clk);
        mem_ready = 0;
        
        $display("Test finished.");
        $finish;
    end

endmodule
