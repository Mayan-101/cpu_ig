`include "defines.vh"

module ex_stage (
    input  wire clk,
    input  wire rst,
    
    // ID/EX Pipeline Register Inputs
    input  wire [5:0]  id_ex_alu_op,
    input  wire [7:0]  id_ex_funct,
    input  wire id_ex_mem_read,
    input  wire id_ex_mem_write,
    input  wire id_ex_reg_write,
    input  wire id_ex_branch,
    input  wire id_ex_jump,
    input  wire id_ex_is_float,
    input  wire id_ex_is_io,
    input  wire id_ex_is_halt,
    input  wire [1:0] id_ex_wb_src,
    input  wire id_ex_alu_src,
    
    input  wire [31:0] id_ex_rs1_data,
    input  wire [31:0] id_ex_rs2_data,
    input  wire [31:0] id_ex_imm32,
    
    input  wire [5:0]  id_ex_rd_addr,
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
    output reg  [5:0]  ex_mem_rd_addr,
    
    output reg  ex_mem_mem_read,
    output reg  ex_mem_mem_write,
    output reg  ex_mem_reg_write,
    output reg  ex_mem_is_io,
    output reg  [1:0] ex_mem_wb_src,
    output reg         ex_mem_is_halt,
    
    // Branch Outcome
    output wire        take_branch,
    output wire [31:0] branch_target
);

    wire [31:0] valA = (forwardA == 2'b10) ? fwd_ex_mem_data :
                       (forwardA == 2'b01) ? fwd_mem_wb_data :
                       id_ex_rs1_data;

    wire [31:0] valB = (forwardB == 2'b10) ? fwd_ex_mem_data :
                       (forwardB == 2'b01) ? fwd_mem_wb_data :
                       id_ex_rs2_data;

    wire [31:0] alu_in_a = valA;
    wire [31:0] alu_in_b = id_ex_alu_src ? id_ex_imm32 : valB;

    reg [5:0] alu_top_op;
    wire is_mul = (id_ex_alu_op == `OP_MUL);
    wire is_div = (id_ex_alu_op == `OP_DIV);
    wire is_multi_cycle = is_mul || is_div || id_ex_is_float; 

    always @(*) begin
        if (id_ex_is_float) begin
            if (id_ex_alu_op == `OP_FADD) alu_top_op = `OP_FADD; 
            else if (id_ex_alu_op == `OP_FSUB) alu_top_op = `OP_FSUB;
            else if (id_ex_alu_op == `OP_FMUL) alu_top_op = `OP_FMUL;
            else alu_top_op = `OP_FADD;
        end else if (is_mul) begin
            alu_top_op = `OP_MUL;
        end else if (is_div) begin
            alu_top_op = `OP_DIV;
        end else begin
            alu_top_op = id_ex_alu_op;
        end
    end

    wire [31:0] alu_result;
    wire alu_done;
    wire [31:0] psw_out;

    reg alu_started;
    always @(posedge clk) begin
        if (rst)
            alu_started <= 1'b0;
        else if (alu_done)
            alu_started <= 1'b0;          // clear only when operation finishes
        else if (is_multi_cycle && !alu_started)
            alu_started <= 1'b1;          // set on first cycle of operation
    end
    wire start_alu = is_multi_cycle && !alu_started;

    alu_top alu_inst (
        .clk(clk), .rst(rst), .start(start_alu),
        .a(alu_in_a), .b(alu_in_b), .op(alu_top_op),
        .result(alu_result), .done(alu_done), .psw_out(psw_out)
    );

    branch_target_calc btc (
        .pc(id_ex_pc_plus4), .imm32(id_ex_imm32), .valA(valA), .valB(valB),
        .opcode(id_ex_alu_op), .branch(id_ex_branch), .jump(id_ex_jump),
        .target(branch_target), .take_branch(take_branch)
    );

    assign alu_stall = is_multi_cycle && !alu_done;

    always @(posedge clk) begin
        if (rst) begin
            ex_mem_alu_result <= 0;
            ex_mem_zero <= 0;
            ex_mem_wr_data <= 0;
            ex_mem_rd_addr <= 0;
            ex_mem_mem_read <= 0;
            ex_mem_mem_write <= 0;
            ex_mem_reg_write <= 0;
            ex_mem_is_io <= 0;
            ex_mem_wb_src <= 0;
            ex_mem_is_halt <= 0;
        end else if (!(alu_stall || stall_in)) begin
            ex_mem_alu_result <= alu_result;
            ex_mem_zero <= psw_out[7];
            ex_mem_wr_data <= valB;
            ex_mem_rd_addr <= id_ex_rd_addr;
            ex_mem_mem_read <= id_ex_mem_read;
            ex_mem_mem_write <= id_ex_mem_write;
            ex_mem_reg_write <= id_ex_reg_write;
            ex_mem_is_io <= id_ex_is_io;
            ex_mem_wb_src <= id_ex_wb_src;
            ex_mem_is_halt   <= id_ex_is_halt;
        end
    end

endmodule
