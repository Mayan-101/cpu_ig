`include "defines.vh"

/*
 * Module: ex_stage
 * Description: Execute stage for RISC-V pipeline.
 *              Routes ALU operations based on opcode/funct3/funct7.
 */
module ex_stage (
    input  wire clk,
    input  wire rst,

    // ID/EX Pipeline Register Inputs
    input  wire [6:0]  id_ex_opcode,
    input  wire [2:0]  id_ex_funct3,
    input  wire [6:0]  id_ex_funct7,
    input  wire id_ex_mem_read,
    input  wire id_ex_mem_write,
    input  wire id_ex_reg_write,
    input  wire id_ex_branch,
    input  wire id_ex_jump,
    input  wire id_ex_is_float,
    input  wire id_ex_is_io,
    input  wire id_ex_is_halt,
    input  wire id_ex_is_reti,
    input  wire [1:0] id_ex_wb_src,
    input  wire id_ex_alu_src,

    input  wire [31:0] id_ex_rs1_data,
    input  wire [31:0] id_ex_rs2_data,
    input  wire [31:0] id_ex_imm32,
    input  wire [31:0] id_ex_mepc,

    input  wire [4:0]  id_ex_rd_addr,
    input  wire [31:0] id_ex_pc_plus4,

    // Forwarding Inputs
    input  wire [31:0] fwd_ex_mem_data,
    input  wire [31:0] fwd_mem_wb_data,
    input  wire [1:0]  forwardA,
    input  wire [1:0]  forwardB,

    // Stall/Flush Control
    input  wire stall_in,
    output wire alu_stall,

    // EX/MEM Pipeline Register Outputs
    output reg  [31:0] ex_mem_alu_result,
    output reg  ex_mem_zero,
    output reg  [31:0] ex_mem_wr_data,
    output reg  [4:0]  ex_mem_rd_addr,

    output reg  ex_mem_mem_read,
    output reg  ex_mem_mem_write,
    output reg  ex_mem_reg_write,
    output reg  ex_mem_is_io,
    output reg  [1:0] ex_mem_wb_src,
    output reg  [2:0] ex_mem_funct3,
    output reg  [31:0] ex_mem_pc_plus4,
    output reg         ex_mem_is_halt,

    // Branch Outcome
    output wire        take_branch,
    output wire [31:0] branch_target
);

    // --- Forwarded values ---
    wire [31:0] valA = (forwardA == 2'b10) ? fwd_ex_mem_data :
                       (forwardA == 2'b01) ? fwd_mem_wb_data :
                       id_ex_rs1_data;

    wire [31:0] valB = (forwardB == 2'b10) ? fwd_ex_mem_data :
                       (forwardB == 2'b01) ? fwd_mem_wb_data :
                       id_ex_rs2_data;

    wire [31:0] alu_in_a = (id_ex_opcode == `OPC_AUIPC) ? (id_ex_pc_plus4 - 32'd4) : valA;
    wire [31:0] alu_in_b = id_ex_alu_src ? id_ex_imm32 : valB;

    // --- ALU operation routing ---
    // For the integer ALU, we pass opcode/funct3/funct7 through to alu_top
    wire is_mul = (id_ex_opcode == `OPC_OP) && (id_ex_funct7 == `F7_MULDIV) &&
                  (id_ex_funct3 == `F3_MUL || id_ex_funct3 == `F3_MULH || id_ex_funct3 == `F3_MULHSU || id_ex_funct3 == `F3_MULHU);
    wire is_div = (id_ex_opcode == `OPC_OP) && (id_ex_funct7 == `F7_MULDIV) &&
                  (id_ex_funct3 == `F3_DIV || id_ex_funct3 == `F3_DIVU || id_ex_funct3 == `F3_REM || id_ex_funct3 == `F3_REMU);

    wire is_multi_cycle = is_mul || is_div || id_ex_is_float;

    wire [31:0] alu_result;
    wire alu_done;
    wire [31:0] psw_out;

    wire [31:0] alu_res_int, alu_res_float;
    wire alu_done_int, alu_done_float;
    wire [31:0] psw_int, psw_float;


    reg alu_started;
    always @(posedge clk) begin
        if (rst)
            alu_started <= 1'b0;
        else if (alu_done)
            alu_started <= 1'b0;
        else if (is_multi_cycle && !alu_started)
            alu_started <= 1'b1;
    end
    wire start_alu = is_multi_cycle && !alu_started;

    alu_top alu_inst (
        .clk(clk), .rst(rst), .start(start_alu),
        .a(alu_in_a), .b(alu_in_b),
        .opcode(id_ex_opcode), .funct3(id_ex_funct3), .funct7(id_ex_funct7),
        .result(alu_res_int), .done(alu_done_int), .psw_out(psw_int)
    );

    fpu_top fpu_inst (
        .clk(clk), .rst(rst), .enable(id_ex_is_float), .start(start_alu),
        .a(alu_in_a), .b(alu_in_b), .funct7(id_ex_funct7),
        .result(alu_res_float), .done(alu_done_float), .psw_out(psw_float)
    );

    assign alu_result = id_ex_is_float ? alu_res_float : alu_res_int;
    assign alu_done   = id_ex_is_float ? alu_done_float : alu_done_int;
    assign psw_out    = id_ex_is_float ? psw_float : psw_int;

    branch_target_calc btc (
        .pc(id_ex_pc_plus4), .imm32(id_ex_imm32),
        .valA(valA), .valB(valB), .mepc(id_ex_mepc),
        .opcode(id_ex_opcode), .funct3(id_ex_funct3),
        .branch(id_ex_branch), .jump(id_ex_jump),
        .is_reti(id_ex_is_reti),
        .target(branch_target), .take_branch(take_branch)
    );



    assign alu_stall = is_multi_cycle && !alu_done;

    // --- Pipeline Register ---
    always @(posedge clk) begin
        if (rst) begin
            ex_mem_alu_result <= 0;
            ex_mem_zero       <= 0;
            ex_mem_wr_data    <= 0;
            ex_mem_rd_addr    <= 0;
            ex_mem_mem_read   <= 0;
            ex_mem_mem_write  <= 0;
            ex_mem_reg_write  <= 0;
            ex_mem_is_io      <= 0;
            ex_mem_wb_src     <= 0;
            ex_mem_funct3     <= 0;
            ex_mem_pc_plus4   <= 0;
            ex_mem_is_halt    <= 0;
        end else if (!(alu_stall || stall_in)) begin
            ex_mem_alu_result <= alu_result;
            ex_mem_zero       <= psw_out[7];
            ex_mem_wr_data    <= valB;
            ex_mem_rd_addr    <= id_ex_rd_addr;
            ex_mem_mem_read   <= id_ex_mem_read;
            ex_mem_mem_write  <= id_ex_mem_write;
            ex_mem_reg_write  <= id_ex_reg_write;
            ex_mem_is_io      <= id_ex_is_io;
            ex_mem_wb_src     <= id_ex_wb_src;
            ex_mem_funct3     <= id_ex_funct3;
            ex_mem_pc_plus4   <= id_ex_pc_plus4;
            ex_mem_is_halt    <= id_ex_is_halt;
        end

    end

endmodule
