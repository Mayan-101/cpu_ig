`timescale 1ns / 1ps

module tb_pc_reg;

    reg clk;
    reg rst;
    reg [31:0] next_pc;
    reg pc_we;
    wire [31:0] pc;

    pc_reg dut (
        .clk(clk),
        .rst(rst),
        .next_pc(next_pc),
        .pc_we(pc_we),
        .pc(pc)
    );

    always #5 clk = ~clk;

    initial begin
        $display("--- M9.1: Program Counter Test ---");
        clk = 0;
        rst = 1;
        next_pc = 0;
        pc_we = 0;
        
        #15;
        rst = 0;
        #1;
        $display("After reset, PC = %h (Expected: 00000000)", pc);
        if (pc !== 32'h00000000) $display("FAIL: Reset");

        // Increment by 4
        @(negedge clk);
        next_pc = pc + 4;
        pc_we = 1;
        @(negedge clk);
        #1;
        $display("Incremented PC = %h (Expected: 00000004)", pc);
        if (pc !== 32'h00000004) $display("FAIL: Increment");

        @(negedge clk);
        next_pc = pc + 4;
        pc_we = 1;
        @(negedge clk);
        #1;
        $display("Incremented PC = %h (Expected: 00000008)", pc);
        if (pc !== 32'h00000008) $display("FAIL: Increment");

        // Load arbitrary value
        @(negedge clk);
        next_pc = 32'h00001234;
        pc_we = 1;
        @(negedge clk);
        #1;
        $display("Jump PC = %h (Expected: 00001234)", pc);
        if (pc !== 32'h00001234) $display("FAIL: Jump");
        
        // Disabled write
        @(negedge clk);
        next_pc = 32'hFFFFFFFF;
        pc_we = 0;
        @(negedge clk);
        #1;
        $display("Hold PC = %h (Expected: 00001234)", pc);
        if (pc !== 32'h00001234) $display("FAIL: Write Enable");

        $display("Test finished.");
        $finish;
    end

endmodule
