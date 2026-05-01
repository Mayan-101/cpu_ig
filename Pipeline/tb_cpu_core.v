`timescale 1ns / 1ps

module tb_cpu_core();

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
    reg [31:0] imem [0:63];
    always @(*) begin
        instr_in = imem[pc[7:2]];
    end

    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    integer i;
    initial begin
        // Initialize Memory
        for (i=0; i<64; i=i+1) begin
            imem[i] = 32'h00000000; // NOP
        end

        /**
         * Test Sequence (10 R-type ALU):
         * 0x00: ADD R1, R2, R3 (10+20=30)     - 0x04108300
         * 0x04: SUB R4, R1, R2 (30-10=20)     - 0x08404200
         * 0x08: AND R5, R4, R1 (20&30=20)     - 0x0C510100
         * 0x0C: OR  R6, R5, R4 (20|20=20)     - 0x10614400
         * 0x10: XOR R7, R6, R5 (20^20=0)      - 0x14718500
         * 0x14: SLL R8, R1, R2 (30<<10=30720) - 0x1C804200
         * 0x18: SRL R9, R8, R2 (30720>>10=30) - 0x20920200
         * 0x1C: ADD R10, R9, R7 (30+0=30)     - 0x04A24700
         * 0x20: SUB R11, R10, R1 (30-30=0)    - 0x08B28100
         * 0x24: AND R12, R11, R10 (0&30=0)    - 0x0CC2C100
         */
        imem[0] = 32'h04108300; 
        imem[1] = 32'h08404200;
        imem[2] = 32'h0C510100;
        imem[3] = 32'h10614400;
        imem[4] = 32'h14718500;
        imem[5] = 32'h1C804200;
        imem[6] = 32'h20920200;
        imem[7] = 32'h04A24700;
        imem[8] = 32'h08B28100;
        imem[9] = 32'h0CC2C100;

        rst = 1;
        #20 rst = 0;

        // Pre-fill registers R2 and R3
        // We'll use force then release after a few cycles
        // Physical R2 is bank0 index 2, R3 is bank0 index 3
        force uut.rf.banks[0].bank_inst.bank[2].r.q = 10;
        force uut.rf.banks[0].bank_inst.bank[3].r.q = 20;

        $display(".1 — CPU Core Integration Test (Sequential ALU)");
        $monitor("Time=%0t | PC=%h | Instr=%h | Stall=%b", 
                 $time, pc, instr_in, uut.stall_haz);

        #30;
        release uut.rf.banks[0].bank_inst.bank[2].r.q;
        release uut.rf.banks[0].bank_inst.bank[3].r.q;

        #300;

        $display("Final Register Verification:");
        $display("R1 (exp 30): %d", uut.rf.banks[0].bank_inst.bank[1].r.q);
        $display("R4 (exp 20): %d", uut.rf.banks[0].bank_inst.bank[4].r.q);
        $display("R5 (exp 20): %d", uut.rf.banks[0].bank_inst.bank[5].r.q);
        $display("R6 (exp 20): %d", uut.rf.banks[0].bank_inst.bank[6].r.q);
        $display("R7 (exp 0):  %d", uut.rf.banks[0].bank_inst.bank[7].r.q);
        $display("R8 (exp 30720): %d", uut.rf.banks[1].bank_inst.bank[0].r.q);
        $display("R9 (exp 30): %d", uut.rf.banks[1].bank_inst.bank[1].r.q);
        $display("R10 (exp 30):%d", uut.rf.banks[1].bank_inst.bank[2].r.q);
        $display("R11 (exp 0): %d", uut.rf.banks[1].bank_inst.bank[3].r.q);
        $display("R12 (exp 0): %d", uut.rf.banks[1].bank_inst.bank[4].r.q);

        if (uut.rf.banks[1].bank_inst.bank[1].r.q == 30 && uut.rf.banks[1].bank_inst.bank[4].r.q == 0)
            $display("PASS: .1 Sequential ALU test successful!");
        else
            $display("FAIL: .1 Register mismatch.");

        $finish;
    end

endmodule
