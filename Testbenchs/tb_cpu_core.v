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

    reg [31:0] imem [0:63];
    always @(*) begin
        instr_in = imem[pc[7:2]];
    end

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    integer i;
    initial begin
        for (i=0; i<64; i=i+1) imem[i] = 32'h00000013; // NOP (ADDI x0, x0, 0)

        // RISC-V Sequential ALU Test
        imem[0] = 32'h003100b3; // ADD x1, x2, x3
        imem[1] = 32'h40208233; // SUB x4, x1, x2
        imem[2] = 32'h001272b3; // AND x5, x4, x1
        imem[3] = 32'h0042e333; // OR  x6, x5, x4
        imem[4] = 32'h005343b3; // XOR x7, x6, x5
        imem[5] = 32'h00209433; // SLL x8, x1, x2 (Shift by 10)
        imem[6] = 32'h002454b3; // SRL x9, x8, x2 (Shift back)
        imem[7] = 32'h00748533; // ADD x10, x9, x7
        imem[8] = 32'h401505b3; // SUB x11, x10, x1
        imem[9] = 32'h00a5f633; // AND x12, x11, x10

        rst = 1;
        #20 rst = 0;

        force uut.rf.gp_regs[2].reg_inst.q = 10;
        force uut.rf.gp_regs[3].reg_inst.q = 20;

        $display("--- RISC-V CPU Core Sequential ALU Test ---");
        #30;
        release uut.rf.gp_regs[2].reg_inst.q;
        release uut.rf.gp_regs[3].reg_inst.q;

        #500;

        $display("Final Register Verification:");
        $display("x1 (exp 30): %d", uut.rf.gp_regs[1].reg_inst.q);
        $display("x4 (exp 20): %d", uut.rf.gp_regs[4].reg_inst.q);
        $display("x9 (exp 30): %d", uut.rf.gp_regs[9].reg_inst.q);
        $display("x12(exp 0):  %d", uut.rf.gp_regs[12].reg_inst.q);

        if (uut.rf.gp_regs[9].reg_inst.q == 30 && uut.rf.gp_regs[12].reg_inst.q == 0)
            $display("SUCCESS: CPU Core test passed!");
        else
            $display("FAIL: Register mismatch.");

        $finish;
    end

endmodule
