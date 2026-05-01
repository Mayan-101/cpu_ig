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
    
    wire [5:0] rs1_addr;
    wire [5:0] rs2_addr;
    
    wire [5:0] id_ex_alu_op;
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
    
    wire [5:0] id_ex_rd_addr;
    wire [5:0] id_ex_rs1_addr;
    wire [5:0] id_ex_rs2_addr;
    wire [31:0] id_ex_pc_plus4;

    id_stage dut (
        .clk(clk),
        .rst(rst),
        .flush(flush),
        .stall(stall),
        .if_id_instr(if_id_instr),
        .if_id_pc_plus4(if_id_pc_plus4),
        .regfile_rs1(regfile_rs1),
        .regfile_rs2(regfile_rs2),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .id_ex_alu_op(id_ex_alu_op),
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
        .id_ex_pc_plus4(id_ex_pc_plus4)
    );

    always #5 clk = ~clk;

    initial begin
        $display("--- M9.5: Instruction Decode Stage Test ---");
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

        // Test 1: ADD R1, R2, R3 (opcode=01, rd=01, rs1=02, rs2=03)
        // [31:26]=01, [25:20]=01, [19:14]=02, [13:8]=03, [7:0]=00
        @(negedge clk);
        if_id_instr = {6'h01, 6'h01, 6'h02, 6'h03, 8'h00};
        regfile_rs1 = 32'hAAAA_AAAA;
        regfile_rs2 = 32'hBBBB_BBBB;
        
        #1; // combinationally check addrs
        if (rs1_addr !== 6'h02 || rs2_addr !== 6'h03) $display("FAIL: ADD addr");
        
        @(negedge clk);
        #1;
        $display("ADD Decoded: alu_src=%b, rd=%d, rs1=%d, rs2=%d", id_ex_alu_src, id_ex_rd_addr, id_ex_rs1_addr, id_ex_rs2_addr);
        if (id_ex_alu_src !== 0 || id_ex_reg_write !== 1) $display("FAIL: ADD ctrl");

        // Test 2: LW R4, 100(R5) (opcode=20, rd=04, rs1=05, imm14=100)
        @(negedge clk);
        if_id_instr = {6'h20, 6'h04, 6'h05, 14'd100};
        
        #1;
        if (rs1_addr !== 6'h05) $display("FAIL: LW addr");
        
        @(negedge clk);
        #1;
        $display("LW Decoded: imm32=%d, alu_src=%b", id_ex_imm32, id_ex_alu_src);
        if (id_ex_imm32 !== 32'd100 || id_ex_alu_src !== 1 || id_ex_mem_read !== 1) $display("FAIL: LW ctrl");

        // Test 3: BEQ R6, R7, -4 (opcode=30, rd=06, rs1=07, imm14=0x3FFC)
        @(negedge clk);
        if_id_instr = {6'h30, 6'h06, 6'h07, 14'h3FFC};
        
        #1;
        // rd vs rs1 -> so rs1=07, rs2=06 (because rd acts as second source)
        if (rs1_addr !== 6'h07 || rs2_addr !== 6'h06) $display("FAIL: BEQ addr");
        
        @(negedge clk);
        #1;
        $display("BEQ Decoded: branch=%b", id_ex_branch);
        if (id_ex_branch !== 1) $display("FAIL: BEQ ctrl");

        $display("Test finished.");
        $finish;
    end

endmodule
