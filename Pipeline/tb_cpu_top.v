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
    reg [31:0] imem [0:63];
    always @(*) begin
        instr_in = imem[pc[7:2]];
    end

    // Mock Data Memory (Word Indexed)
    reg [31:0] dmem [0:63];
    always @(*) begin
        dmem_rd_data = dmem[dmem_addr[7:2]];
    end
    always @(posedge clk) begin
        if (dmem_we) dmem[dmem_addr[7:2]] <= dmem_wr_data;
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
            dmem[i] = 32'h00000000;
        end

        /**
         * Test Sequence:
         * 0x00: ADD R1, R2, R3 (R2=10, R3=20 -> R1=30)  - 0x04108300
         * 0x04: ADD R4, R1, R5 (R1=30, R5=40 -> R4=70)  - 0x04404500 (Forwarded R1)
         * 0x08: LW  R6, 0(R7)  (R7=16, MEM[16]=99)      - 0x8061C000
         * 0x0C: ADD R8, R6, R1 (R6=99, R1=30 -> R8=129) - 0x04818100 (Stall for LW)
         * 0x10: BEQ R1, R4, 2  (30 != 70, Not Taken)    - 0xC0110002
         * 0x14: ADD R9, R1, R1 (R1=30 -> R9=60)         - 0x04904100
         * 0x18: BEQ R1, R1, 2  (30 == 30, Taken)        - 0xC0044002
         * 0x1C: ADD R10, R2, R2 (Flushed)               - 0x04A08200
         * 0x20: ADD R11, R2, R2 (Flushed)               - 0x04B08200
         * 0x24: ADD R12, R2, R2 (Target of branch)      - 0x04C08200
         */
        imem[0] = 32'h04108300; 
        imem[1] = 32'h04404500;
        imem[2] = 32'h8061C000;
        imem[3] = 32'h04818100;
        imem[4] = 32'hC0110002;
        imem[5] = 32'h04904100;
        imem[6] = 32'hC0044002;
        imem[7] = 32'h04A08200;
        imem[8] = 32'h04B08200;
        imem[9] = 32'h04C08200;

        rst = 1;
        #20 rst = 0;

        // Pre-fill registers
        force uut.rf.banks[0].bank_inst.bank[2].r.q = 10;
        force uut.rf.banks[0].bank_inst.bank[3].r.q = 20;
        force uut.rf.banks[0].bank_inst.bank[5].r.q = 40;
        force uut.rf.banks[0].bank_inst.bank[7].r.q = 16; // Byte address 16 = Word index 4
        
        dmem[4] = 99; // Value for LW at address 16

        $display("Starting CPU Pipeline Integration Test...");
        $monitor("Time=%0t | PC=%h | Instr=%h | Stall=%b | FlushIF=%b | FlushID=%b", 
                 $time, pc, instr_in, uut.stall_haz, uut.flush_IF, uut.flush_ID);

        #400;

        $display("Final Register Verification:");
        #1;
        $display("R1 (exp 30): %d", uut.rf.banks[0].bank_inst.bank[1].r.q);
        $display("R4 (exp 70): %d", uut.rf.banks[0].bank_inst.bank[4].r.q);
        $display("R6 (exp 99): %d", uut.rf.banks[0].bank_inst.bank[6].r.q);
        $display("R8 (exp 129): %d", uut.rf.banks[1].bank_inst.bank[0].r.q);
        $display("R9 (exp 60): %d", uut.rf.banks[1].bank_inst.bank[1].r.q);
        $display("R12 (exp 20): %d", uut.rf.banks[1].bank_inst.bank[4].r.q);

        if (uut.rf.banks[1].bank_inst.bank[0].r.q == 129 && uut.rf.banks[1].bank_inst.bank[4].r.q == 20)
            $display("PASS: All hazards handled correctly!");
        else
            $display("FAIL: Final values mismatch.");

        $finish;
    end

    initial begin
        #30;
        release uut.rf.banks[0].bank_inst.bank[1].r.q;
        release uut.rf.banks[0].bank_inst.bank[4].r.q;
        release uut.rf.banks[0].bank_inst.bank[6].r.q;
        release uut.rf.banks[1].bank_inst.bank[0].r.q;
        release uut.rf.banks[1].bank_inst.bank[1].r.q;
        release uut.rf.banks[1].bank_inst.bank[4].r.q;
    end

endmodule
