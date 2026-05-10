`include "defines.vh"
`timescale 1ns / 1ps

module tb_ex_stage;

    reg clk;
    reg rst;
    
    reg [6:0] id_ex_opcode;
    reg [2:0] id_ex_funct3;
    reg [6:0] id_ex_funct7;
    reg id_ex_mem_read;
    reg id_ex_mem_write;
    reg id_ex_reg_write;
    reg id_ex_branch;
    reg id_ex_jump;
    reg id_ex_is_float;
    reg id_ex_is_io;
    reg id_ex_is_halt;
    reg id_ex_is_reti;
    reg [1:0] id_ex_wb_src;
    reg id_ex_alu_src;
    reg [31:0] id_ex_rs1_data;
    reg [31:0] id_ex_rs2_data;
    reg [31:0] id_ex_imm32;
    reg [31:0] id_ex_mepc;
    reg [4:0]  id_ex_rd_addr;
    reg [31:0] id_ex_pc_plus4;
    
    reg stall_in;
    reg [31:0] fwd_ex_mem_data;
    reg [31:0] fwd_mem_wb_data;
    reg [1:0]  forwardA;
    reg [1:0]  forwardB;
    
    wire alu_stall;
    wire [31:0] ex_mem_alu_result;
    wire ex_mem_zero;
    wire [31:0] ex_mem_wr_data;
    wire [4:0]  ex_mem_rd_addr;
    wire ex_mem_mem_read;
    wire ex_mem_mem_write;
    wire ex_mem_reg_write;
    wire ex_mem_is_io;
    wire [1:0] ex_mem_wb_src;
    wire [2:0] ex_mem_funct3;
    wire ex_mem_is_halt;
    wire take_branch;
    wire [31:0] branch_target;

    ex_stage dut (
        .clk(clk),
        .rst(rst),
        .id_ex_opcode(id_ex_opcode),
        .id_ex_funct3(id_ex_funct3),
        .id_ex_funct7(id_ex_funct7),
        .id_ex_mem_read(id_ex_mem_read),
        .id_ex_mem_write(id_ex_mem_write),
        .id_ex_reg_write(id_ex_reg_write),
        .id_ex_branch(id_ex_branch),
        .id_ex_jump(id_ex_jump),
        .id_ex_is_float(id_ex_is_float),
        .id_ex_is_io(id_ex_is_io),
        .id_ex_is_halt(id_ex_is_halt),
        .id_ex_is_reti(id_ex_is_reti),
        .id_ex_wb_src(id_ex_wb_src),
        .id_ex_alu_src(id_ex_alu_src),
        .id_ex_rs1_data(id_ex_rs1_data),
        .id_ex_rs2_data(id_ex_rs2_data),
        .id_ex_imm32(id_ex_imm32),
        .id_ex_mepc(id_ex_mepc),
        .id_ex_rd_addr(id_ex_rd_addr),
        .id_ex_pc_plus4(id_ex_pc_plus4),
        .fwd_ex_mem_data(fwd_ex_mem_data),
        .fwd_mem_wb_data(fwd_mem_wb_data),
        .forwardA(forwardA),
        .forwardB(forwardB),
        .stall_in(stall_in),
        .alu_stall(alu_stall),
        .ex_mem_alu_result(ex_mem_alu_result),
        .ex_mem_zero(ex_mem_zero),
        .ex_mem_wr_data(ex_mem_wr_data),
        .ex_mem_rd_addr(ex_mem_rd_addr),
        .ex_mem_mem_read(ex_mem_mem_read),
        .ex_mem_mem_write(ex_mem_mem_write),
        .ex_mem_reg_write(ex_mem_reg_write),
        .ex_mem_is_io(ex_mem_is_io),
        .ex_mem_wb_src(ex_mem_wb_src),
        .ex_mem_funct3(ex_mem_funct3),
        .ex_mem_is_halt(ex_mem_is_halt),
        .take_branch(take_branch),
        .branch_target(branch_target)
    );


    always #5 clk = ~clk;

    initial begin
        $display("--- RISC-V Execute Stage Test ---");
        clk = 0;
        rst = 1;
        id_ex_opcode = 0;
        id_ex_funct3 = 0;
        id_ex_funct7 = 0;
        id_ex_mem_read = 0;
        id_ex_mem_write = 0;
        id_ex_reg_write = 0;
        id_ex_branch = 0;
        id_ex_jump = 0;
        id_ex_is_float = 0;
        id_ex_is_io = 0;
        id_ex_is_halt = 0;
        id_ex_is_reti = 0;
        id_ex_wb_src = 0;
        id_ex_alu_src = 0;
        id_ex_rs1_data = 0;
        id_ex_rs2_data = 0;
        id_ex_imm32 = 0;
        id_ex_mepc = 0;
        id_ex_rd_addr = 0;

        id_ex_pc_plus4 = 0;
        stall_in = 0;
        fwd_ex_mem_data = 0;
        fwd_mem_wb_data = 0;
        forwardA = 0;
        forwardB = 0;
        
        #15;
        rst = 0;

        // Test 1: ADD x3, x1, x2 (No forwarding)
        @(negedge clk);
        id_ex_opcode = `OPC_OP;
        id_ex_funct3 = `F3_ADD_SUB;
        id_ex_funct7 = `F7_BASE;
        id_ex_alu_src = 0;    // valB
        id_ex_rs1_data = 32'd10;
        id_ex_rs2_data = 32'd20;
        forwardA = 2'b00;
        forwardB = 2'b00;
        
        @(negedge clk);
        #1;
        $display("ADD (no fwd) Result = %d", ex_mem_alu_result);
        if (ex_mem_alu_result !== 32'd30) $display("FAIL: No fwd");

        // Test 2: ADD x3, x1, x2 (forwardA = 10 -> EX/MEM)
        @(negedge clk);
        fwd_ex_mem_data = 32'd50;
        forwardA = 2'b10;
        forwardB = 2'b00;
        
        @(negedge clk);
        #1;
        $display("ADD (fwdA=10) Result = %d", ex_mem_alu_result);
        if (ex_mem_alu_result !== 32'd70) $display("FAIL: fwdA=10");

        // Test 3: ADDI x4, x1, 100 (Immediate src)
        @(negedge clk);
        id_ex_opcode = `OPC_OP_IMM;
        id_ex_funct3 = `F3_ADD_SUB;
        id_ex_alu_src = 1; // imm32
        id_ex_rs1_data = 32'd10;
        id_ex_imm32 = 32'd100;
        forwardA = 2'b00;
        forwardB = 2'b00;
        
        @(negedge clk);
        #1;
        $display("ADDI Result = %d", ex_mem_alu_result);
        if (ex_mem_alu_result !== 32'd110) $display("FAIL: ADDI");

        $display("Test finished.");
        $finish;
    end

endmodule
