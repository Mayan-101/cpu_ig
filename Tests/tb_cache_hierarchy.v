`timescale 1ns / 1ps

module tb_cache_hierarchy;

    reg clk;
    reg rst;
    
    reg l1_miss;
    reg [31:0] l1_addr;
    wire fill_l1;
    wire [63:0] fill_data;
    wire stall_pipeline;
    
    reg l2_hit;
    reg [63:0] l2_data;
    
    wire mem_req;
    wire [31:0] mem_addr;
    reg mem_ready;
    reg [63:0] mem_data;

    cache_hierarchy dut (
        .clk(clk),
        .rst(rst),
        .l1_miss(l1_miss),
        .l1_addr(l1_addr),
        .fill_l1(fill_l1),
        .fill_data(fill_data),
        .stall_pipeline(stall_pipeline),
        .l2_hit(l2_hit),
        .l2_data(l2_data),
        .mem_req(mem_req),
        .mem_addr(mem_addr),
        .mem_ready(mem_ready),
        .mem_data(mem_data)
    );

    always #5 clk = ~clk;

    initial begin
        mem_ready = 0;
        forever begin
            @(posedge clk);
            if (mem_req && !mem_ready) begin
                repeat (7) @(posedge clk);
                mem_data = 64'hBAADF00D_BAADF00D;
                mem_ready = 1;
            end else if (mem_ready) begin
                mem_ready = 0;
            end
        end
    end

    initial begin
        $display("---9: Cache Hierarchy Controller Test ---");
        clk = 0;
        rst = 1;
        l1_miss = 0;
        l1_addr = 0;
        l2_hit = 0;
        l2_data = 0;
        
        #15;
        rst = 0;
        
        // Test 1: L1 miss + L2 hit -> 4-cycle stall
        @(negedge clk);
        l1_miss = 1;
        l1_addr = 32'h00000100;
        l2_hit = 1;
        l2_data = 64'hE2E2E2E2_E2E2E2E2;
        $display("[%0t] L1 miss + L2 hit", $time);
        
        wait(fill_l1 == 1);
        @(negedge clk);
        $display("[%0t] Filled L1 with data: %h", $time, fill_data);
        l1_miss = 0;
        
        // Test 2: L1 miss + L2 miss -> 8-cycle stall
        #10;
        @(negedge clk);
        l1_miss = 1;
        l1_addr = 32'h00000200;
        l2_hit = 0;
        $display("[%0t] L1 miss + L2 miss", $time);
        
        wait(fill_l1 == 1);
        @(negedge clk);
        $display("[%0t] Filled L1 with data: %h", $time, fill_data);
        l1_miss = 0;
        
        $display("Test finished.");
        $finish;
    end

endmodule
