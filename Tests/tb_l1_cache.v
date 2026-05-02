`timescale 1ns / 1ps

module tb_l1_cache;

    reg clk;
    reg reset;
    
    reg [31:0] addr;
    reg [31:0] wr_data;
    reg we;
    reg re;
    wire [31:0] rd_data;
    wire hit;
    wire miss;
    wire stall;
    
    reg [63:0] mem_data;
    reg mem_ready;
    wire mem_req;
    wire [31:0] mem_addr;
    wire mem_we;
    wire [31:0] mem_wr_data;

    l1_cache dut (
        .clk(clk),
        .reset(reset),
        .addr(addr),
        .wr_data(wr_data),
        .we(we),
        .re(re),
        .rd_data(rd_data),
        .hit(hit),
        .miss(miss),
        .stall(stall),
        .mem_data(mem_data),
        .mem_ready(mem_ready),
        .mem_req(mem_req),
        .mem_addr(mem_addr),
        .mem_we(mem_we),
        .mem_wr_data(mem_wr_data)
    );

    always #5 clk = ~clk;

    initial begin
        mem_ready = 0;
        forever begin
            @(posedge clk);
            if (mem_req && !mem_ready) begin
                if (!mem_we) begin
                    repeat (3) @(posedge clk);
                    if (mem_addr == 32'h00000000) mem_data = 64'hBBBBBBBB_AAAAAAAA;
                    else if (mem_addr == 32'h00000010) mem_data = 64'hDDDDDDDD_CCCCCCCC; 
                    else mem_data = 64'h0;
                    mem_ready = 1;
                end else begin
                    repeat (2) @(posedge clk);
                    mem_ready = 1;
                end
            end else if (mem_ready) begin
                mem_ready = 0;
            end
        end
    end

    initial begin
        $dumpfile("tb_l1_cache.vcd");
        $dumpvars(0, tb_l1_cache);
        
        // Timeout
        #5000;
        $display("TIMEOUT!");
        $finish;
    end

    initial begin
        $display("---3: L1 Direct-Mapped Cache Test ---");
        clk = 0;
        reset = 1;
        addr = 0;
        wr_data = 0;
        we = 0;
        re = 0;
        
        #15;
        reset = 0;
        
        // Test 1: Cold compulsory miss
        @(negedge clk);
        addr = 32'h00000000;
        re = 1;
        $display("[%0t] READ ADDR %h", $time, addr);
        
        wait(stall == 1);
        $display("[%0t] STALL asserted. Miss = %b, Mem Req = %b", $time, miss, mem_req);
        wait(stall == 0);
        @(negedge clk);
        $display("[%0t] HIT = %b, Data = %h", $time, hit, rd_data);
        if (rd_data !== 32'hAAAAAAAA) $display("FAIL: Expected AAAAAAAA.");
        re = 0;
        
        // Test 2: Same address again -> hit
        #10;
        @(negedge clk);
        addr = 32'h00000004; // upper word of same line
        re = 1;
        $display("[%0t] READ ADDR %h", $time, addr);
        #1;
        $display("[%0t] STALL = %b, HIT = %b, Data = %h", $time, stall, hit, rd_data);
        if (rd_data !== 32'hBBBBBBBB || stall !== 0 || hit !== 1) $display("FAIL: Expected BBBBBBBB hit.");
        @(negedge clk);
        re = 0;

        // Test 3: Conflict miss (eviction)
        #10;
        @(negedge clk);
        addr = 32'h00000010;
        re = 1;
        $display("[%0t] READ ADDR %h (Conflict)", $time, addr);
        wait(stall == 1);
        $display("[%0t] STALL asserted. Miss = %b", $time, miss);
        wait(stall == 0);
        @(negedge clk);
        $display("[%0t] HIT = %b, Data = %h", $time, hit, rd_data);
        if (rd_data !== 32'hCCCCCCCC) $display("FAIL: Expected CCCCCCCC.");
        re = 0;
        
        // Test 4: Write hit
        #10;
        @(negedge clk);
        addr = 32'h00000014;
        we = 1;
        wr_data = 32'h12345678;
        $display("[%0t] WRITE ADDR %h Data %h", $time, addr, wr_data);
        wait(stall == 1);
        wait(stall == 0);
        @(negedge clk);
        we = 0;
        
        // verify write hit with read
        @(negedge clk);
        re = 1;
        addr = 32'h00000014;
        #1;
        $display("[%0t] READ ADDR %h, HIT=%b, Data=%h", $time, addr, hit, rd_data);
        if (rd_data !== 32'h12345678 || hit !== 1) $display("FAIL: Expected 12345678 hit.");
        re = 0;
        
        #20;
        $display("All tests completed.");
        $finish;
    end

endmodule
