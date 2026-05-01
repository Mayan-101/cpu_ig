`timescale 1ns / 1ps

module tb_lru_unit;

    reg clk;
    reg rst;
    reg [1:0] access_way;
    reg update_en;
    wire [1:0] lru_way;

    lru_unit dut (
        .clk(clk),
        .rst(rst),
        .access_way(access_way),
        .update_en(update_en),
        .lru_way(lru_way)
    );

    always #5 clk = ~clk;

    initial begin
        $display("---4: LRU Replacement Unit Test ---");
        clk = 0;
        rst = 1;
        access_way = 0;
        update_en = 0;
        
        #15;
        rst = 0;
        
        // Test: Access sequence 0,1,2,3 -> LRU=0.
        // Then access 0 -> LRU=1. Access 0,1,2,3,0 -> LRU=1. Reset -> LRU=0.

        // Access 0
        @(negedge clk);
        update_en = 1;
        access_way = 0;
        
        // Access 1
        @(negedge clk);
        access_way = 1;

        // Access 2
        @(negedge clk);
        access_way = 2;

        // Access 3
        @(negedge clk);
        access_way = 3;

        @(negedge clk);
        update_en = 0;
        #1;
        $display("After 0,1,2,3 -> LRU is: %d", lru_way);
        if (lru_way !== 2'd0) $display("FAIL: Expected LRU=0");

        // Then access 0
        @(negedge clk);
        update_en = 1;
        access_way = 0;
        
        @(negedge clk);
        update_en = 0;
        #1;
        $display("After 0 -> LRU is: %d", lru_way);
        if (lru_way !== 2'd1) $display("FAIL: Expected LRU=1");

        // Reset
        @(negedge clk);
        rst = 1;
        @(negedge clk);
        rst = 0;
        #1;
        $display("After Reset -> LRU is: %d", lru_way);
        if (lru_way !== 2'd0) $display("FAIL: Expected LRU=0");

        $finish;
    end

endmodule
