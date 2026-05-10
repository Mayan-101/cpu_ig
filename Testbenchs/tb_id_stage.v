`include "defines.vh"
`timescale 1ns / 1ps

module tb_id_stage;

    reg clk;
    reg rst;
    reg flush;
    reg stall;
    
    reg [31:0] if_id_instr;
    reg [31:0] if_id_pc_plus4;
    reg [31:0] regfile_rs1;
    reg [31:0] regfile_rs2;
    reg [31:0] mepc;
    
    wire [4:0] rs1_addr;
    wire [4:0] rs2_addr;
    
    wire [6:0]  id_ex_opcode;
    wire [2:0]  id_ex_funct3;
    wire [6:0]  id_ex_funct7;
    wire id_ex_mem_read;
    wire id_ex_mem_write;
    wire id_ex_reg_write;
    wire id_ex_branch;
    wire id_ex_jump;
    wire id_ex_is_float;
    wire id_ex_is_io;
    wire [1:0] id_ex_wb_src;
    wire id_ex_alu_src;
    
    wire [31:0] id_ex_rs1_data;
    wire [31:0] id_ex_rs2_data;
    wire [31:0] id_ex_imm32;
    
    wire [4:0]  id_ex_rd_addr;
    wire [4:0]  id_ex_rs1_addr;
    wire [4:0]  id_ex_rs2_addr;
    wire [31:0] id_ex_pc_plus4;
    wire [31:0] id_ex_mepc;
    wire [11:0] id_ex_csr_addr;
    wire [4:0]  id_ex_imm5;
    wire        id_ex_ecall;
    wire id_ex_is_reti;
    wire id_ex_is_halt;


    id_stage dut (
        .clk(clk),
        .rst(rst),
        .flush(flush),
        .stall(stall),
        .if_id_instr(if_id_instr),
        .if_id_pc_plus4(if_id_pc_plus4),
        .regfile_rs1(regfile_rs1),
        .regfile_rs2(regfile_rs2),
        .mepc(mepc),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
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
        .id_ex_wb_src(id_ex_wb_src),
        .id_ex_alu_src(id_ex_alu_src),
        .id_ex_rs1_data(id_ex_rs1_data),
        .id_ex_rs2_data(id_ex_rs2_data),
        .id_ex_imm32(id_ex_imm32),
        .id_ex_rd_addr(id_ex_rd_addr),
        .id_ex_rs1_addr(id_ex_rs1_addr),
        .id_ex_rs2_addr(id_ex_rs2_addr),
        .id_ex_pc_plus4(id_ex_pc_plus4),
        .id_ex_mepc(id_ex_mepc),
        .id_ex_csr_addr(id_ex_csr_addr),
        .id_ex_imm5(id_ex_imm5),
        .id_ex_ecall(id_ex_ecall),
        .id_ex_is_reti(id_ex_is_reti),
        .id_ex_is_halt(id_ex_is_halt)
    );


    always #5 clk = ~clk;

    initial begin
        $display("--- RISC-V Instruction Decode Stage Test ---");
        clk = 0;
        rst = 1;
        flush = 0;
        stall = 0;
        if_id_instr = 0;
        if_id_pc_plus4 = 0;
        regfile_rs1 = 0;
        regfile_rs2 = 0;
        
        #15;
        rst = 0;

        // Test 1: ADD x3, x1, x2
        // R-type: funct7(0000000) rs2(00010) rs1(00001) funct3(000) rd(00011) opcode(0110011)
        @(negedge clk);
        if_id_instr = 32'b0000000_00010_00001_000_00011_0110011;
        regfile_rs1 = 32'hAAAA_AAAA;
        regfile_rs2 = 32'hBBBB_BBBB;
        
        #1;
        if (rs1_addr !== 5'd1 || rs2_addr !== 5'd2) $display("FAIL: ADD addr rs1=%d rs2=%d", rs1_addr, rs2_addr);
        
        @(negedge clk);
        #1;
        $display("ADD Decoded: rd=%d, rs1=%d, rs2=%d, rs1_data=%h", id_ex_rd_addr, id_ex_rs1_addr, id_ex_rs2_addr, id_ex_rs1_data);
        if (id_ex_rd_addr !== 5'd3 || id_ex_reg_write !== 1) $display("FAIL: ADD ctrl");

        // Test 2: ADDI x4, x1, 100
        // I-type: imm[11:0](100) rs1(00001) funct3(000) rd(00100) opcode(0010011)
        @(negedge clk);
        if_id_instr = {12'd100, 5'd1, 3'b000, 5'd4, 7'b0010011};
        
        #1;
        if (rs1_addr !== 5'd1) $display("FAIL: ADDI addr");
        
        @(negedge clk);
        #1;
        $display("ADDI Decoded: imm32=%d, alu_src=%b", id_ex_imm32, id_ex_alu_src);
        if (id_ex_imm32 !== 32'd100 || id_ex_alu_src !== 1) $display("FAIL: ADDI ctrl");

        // Test 3: LW x5, 40(x1)
        // I-type: imm[11:0](40) rs1(00001) funct3(010) rd(00101) opcode(0000011)
        @(negedge clk);
        if_id_instr = {12'd40, 5'd1, 3'b010, 5'd5, 7'b0000011};
        
        @(negedge clk);
        #1;
        $display("LW Decoded: mem_read=%b, wb_src=%b", id_ex_mem_read, id_ex_wb_src);
        if (id_ex_mem_read !== 1 || id_ex_wb_src !== 2'b01) $display("FAIL: LW ctrl");

        $display("Test finished.");
        $finish;
    end

endmodule
