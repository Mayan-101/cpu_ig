`timescale 1ns / 1ps

module tb_if_stage;

    reg clk;
    reg rst;
    
    reg [31:0] pc;
    reg [31:0] icache_data;
    reg icache_hit;
    reg flush;
    
    wire [31:0] if_id_instr;
    wire [31:0] if_id_pc_plus4;
    wire stall;

    if_stage dut (
        .clk(clk),
        .rst(rst),
        .pc(pc),
        .icache_data(icache_data),
        .icache_hit(icache_hit),
        .flush(flush),
        .if_id_instr(if_id_instr),
        .if_id_pc_plus4(if_id_pc_plus4),
        .stall_in(1'b0),
        .stall_out(stall)
    );

    always #5 clk = ~clk;

    initial begin
        $display("--- M9.2: Instruction Fetch Stage Test ---");
        clk = 0;
        rst = 1;
        pc = 0;
        icache_data = 0;
        icache_hit = 1;
        flush = 0;
        
        #15;
        rst = 0;
        
        // Cache hit -> IF/ID filled next cycle
        @(negedge clk);
        pc = 32'h00000100;
        icache_data = 32'hAABBCCDD;
        icache_hit = 1;
        
        @(negedge clk);
        #1;
        $display("Hit Test: instr=%h, pc_plus4=%h", if_id_instr, if_id_pc_plus4);
        if (if_id_instr !== 32'hAABBCCDD || if_id_pc_plus4 !== 32'h00000104) $display("FAIL: Hit");
        
        // Cache miss -> stall=1, IF/ID holds
        @(negedge clk);
        pc = 32'h00000104;
        icache_data = 32'hEEEEEEEE;
        icache_hit = 0;
        
        @(negedge clk);
        #1;
        $display("Miss Test: stall=%b, held instr=%h", stall, if_id_instr);
        if (stall !== 1 || if_id_instr !== 32'hAABBCCDD) $display("FAIL: Miss");
        
        // Cache hit after miss
        @(negedge clk);
        icache_hit = 1;
        
        @(negedge clk);
        #1;
        $display("Recovered Hit Test: instr=%h", if_id_instr);
        if (if_id_instr !== 32'hEEEEEEEE) $display("FAIL: Hit after miss");
        
        // NOP injection on branch flush
        @(negedge clk);
        pc = 32'h00000200;
        icache_data = 32'h11223344;
        flush = 1;
        
        @(negedge clk);
        #1;
        $display("Flush Test: instr=%h (Expected 00000000)", if_id_instr);
        if (if_id_instr !== 32'h00000000) $display("FAIL: Flush");
        flush = 0;

        $display("Test finished.");
        $finish;
    end

endmodule
