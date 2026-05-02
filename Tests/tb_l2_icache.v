`timescale 1ns / 1ps

module tb_l2_icache;

    reg clk;
    reg rst;
    
    reg [31:0] i_addr;
    reg re;
    wire [63:0] instr_data;
    wire hit;
    wire stall;
    
    reg [63:0] mem_data;
    reg mem_ready;
    wire mem_req;
    wire [31:0] mem_addr;

    l2_icache dut (
        .clk(clk),
        .rst(rst),
        .i_addr(i_addr),
        .re(re),
        .instr_data(instr_data),
        .hit(hit),
        .stall(stall),
        .mem_data(mem_data),
        .mem_ready(mem_ready),
        .mem_req(mem_req),
        .mem_addr(mem_addr)
    );

    always #5 clk = ~clk;

    initial begin
        mem_ready = 0;
        forever begin
            @(posedge clk);
            if (mem_req && !mem_ready) begin
                repeat (2) @(posedge clk);
                mem_data = {mem_addr[31:0], mem_addr[31:0]};
                mem_ready = 1;
            end else if (mem_ready) begin
                mem_ready = 0;
            end
        end
    end

    task read_cache(input [31:0] a, output h);
    begin
        @(negedge clk);
        i_addr = a;
        re = 1;
        #1;
        h = hit;
        if (stall) begin
            wait(stall == 0);
        end
        @(negedge clk);
        re = 0;
    end
    endtask

    reg h_res;

    initial begin
        $display("---6: L2 Instruction Cache Test ---");
        clk = 0;
        rst = 1;
        i_addr = 0;
        re = 0;
        
        #15;
        rst = 0;
        
        // Fill Set 0
        read_cache(32'h00000000, h_res);
        read_cache(32'h00000010, h_res);
        read_cache(32'h00000020, h_res);
        read_cache(32'h00000030, h_res);

        // Fill Set 1
        read_cache(32'h00000008, h_res);
        read_cache(32'h00000018, h_res);
        read_cache(32'h00000028, h_res);
        read_cache(32'h00000038, h_res);

        // Verify hits
        read_cache(32'h00000000, h_res);
        if (!h_res) $display("FAIL: Expected hit on 0x00");
        $display("After 0x00 hit, LRU for set 0: %d", dut.core.lru_way_out[0]);
        
        read_cache(32'h00000010, h_res);
        if (!h_res) $display("FAIL: Expected hit on 0x10");
        $display("After 0x10 hit, LRU for set 0: %d", dut.core.lru_way_out[0]);
        
        // LRU Eviction in Set 0
        read_cache(32'h00000040, h_res); 
        $display("After 0x40 fetch, LRU for set 0: %d", dut.core.lru_way_out[0]); 
        read_cache(32'h00000020, h_res);
        if (h_res) $display("FAIL: Expected miss on 0x20");
        
        // LRU Eviction in Set 1
        read_cache(32'h00000048, h_res); 
        read_cache(32'h00000008, h_res);
        if (h_res) $display("FAIL: Expected miss on 0x08");

        $display("Test finished.");
        $finish;
    end

endmodule
