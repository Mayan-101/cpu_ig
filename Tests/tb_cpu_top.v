`timescale 1ns / 1ps

module tb_cpu_top();

    reg clk;
    reg rst;
    
    wire [31:0] pc;
    reg [31:0] instr_in;
    wire icache_hit = 1'b1;
    
    wire [31:0] dmem_addr;
    wire [31:0] dmem_wr_data;
    wire dmem_we;
    wire dmem_re;
    reg [31:0] dmem_rd_data;
    wire dcache_hit = 1'b1;
    
    wire [31:0] io_data_in = 32'd0;

    cpu_top uut (
        .clk(clk), .rst(rst),
        .pc(pc), .instr_in(instr_in), .icache_hit(icache_hit),
        .dmem_addr(dmem_addr), .dmem_wr_data(dmem_wr_data), .dmem_we(dmem_we), .dmem_re(dmem_re),
        .dmem_rd_data(dmem_rd_data), .dcache_ready(dcache_hit),
        .io_data_in(io_data_in)
    );

    // Mock Instruction Memory (Word Indexed)
    reg [31:0] imem [0:255];
    always @(*) begin
        instr_in = imem[pc[9:2]];
    end

    // Mock Data Memory (Word Indexed)
    reg [31:0] dmem [0:255];
    always @(*) begin
        dmem_rd_data = dmem[dmem_addr[9:2]];
    end
    always @(posedge clk) begin
        if (dmem_we) dmem[dmem_addr[9:2]] <= dmem_wr_data;
    end

    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    integer i;
    initial begin
        // Initialize Memory
        for (i=0; i<256; i=i+1) begin
            imem[i] = 32'h00000000; 
            dmem[i] = 32'h00000000;
        end

        $display("Loading Bubble Sort Program...");
        $readmemh("Programs/bubble_sort.mem", imem);
        
        // Initialize data to sort
        dmem[10] = 32'd5;
        dmem[11] = 32'd2;
        dmem[12] = 32'd9;
        dmem[13] = 32'd1;
        dmem[14] = 32'd7;

        rst = 1;
        #20 rst = 0;

        $display("Starting Bubble Sort Execution...");
        
        // Run for a long time
        #50000;

        $display("Bubble Sort Result (Memory 10-14):");
        for (i=10; i<=14; i=i+1) begin
            $display("MEM[%0d] = %d", i, dmem[i]);
        end

        $finish;
    end

endmodule
