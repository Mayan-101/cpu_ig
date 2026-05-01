/*
 * Module: id_stage
 * Description: Instruction Decode stage. Extracts fields, generates control signals, 
 *              performs immediate extension, and manages the ID/EX pipeline register.
 */
module id_stage (
    input  wire        clk,
    input  wire        rst,
    input  wire        flush,
    input  wire        stall,
    
    // IF/ID Pipeline Inputs
    input  wire [31:0] if_id_instr,
    input  wire [31:0] if_id_pc_plus4,
    
    // Register File Inputs
    input  wire [31:0] regfile_rs1,
    input  wire [31:0] regfile_rs2,
    
    // Register File Outputs (Read Addresses)
    output wire [5:0]  rs1_addr,
    output wire [5:0]  rs2_addr,
    
    // ID/EX Pipeline Register Outputs
    output reg  [5:0]  id_ex_alu_op,
    output reg         id_ex_mem_read,
    output reg         id_ex_mem_write,
    output reg         id_ex_reg_write,
    output reg         id_ex_branch,
    output reg         id_ex_jump,
    output reg         id_ex_is_float,
    output reg         id_ex_is_io,
    output reg  [1:0]  id_ex_wb_src,
    output reg         id_ex_alu_src,
    output reg  [31:0] id_ex_rs1_data,
    output reg  [31:0] id_ex_rs2_data,
    output reg  [31:0] id_ex_imm32,
    output reg  [5:0]  id_ex_rd_addr,
    output reg  [5:0]  id_ex_rs1_addr,
    output reg  [5:0]  id_ex_rs2_addr,
    output reg  [31:0] id_ex_pc_plus4
);

    //  Instruction Field Extraction 
    wire [5:0] opcode = if_id_instr[31:26];
    wire [5:0] rd     = if_id_instr[25:20];
    wire [5:0] rs1    = if_id_instr[19:14];
    wire [5:0] rs2    = if_id_instr[13:8];
    wire [7:0] funct  = if_id_instr[7:0];

    wire is_store  = (opcode == 6'h21 || opcode == 6'h23 || opcode == 6'h25);
    wire is_branch = (opcode >= 6'h30 && opcode <= 6'h37);
    
    assign rs1_addr = rs1;
    assign rs2_addr = (is_store || is_branch) ? rd : rs2;

    //  Control Unit and Immediate Extender 
    wire [5:0] ctrl_alu_op;
    wire ctrl_mem_read, ctrl_mem_write, ctrl_reg_write, ctrl_branch;
    wire ctrl_jump, ctrl_is_float, ctrl_is_io, ctrl_alu_src;
    wire [1:0] ctrl_wb_src, ctrl_ext_mode;
    
    control_unit cu (
        .opcode(opcode), .funct(funct),
        .alu_op(ctrl_alu_op), .mem_read(ctrl_mem_read), .mem_write(ctrl_mem_write), .reg_write(ctrl_reg_write),
        .branch(ctrl_branch), .jump(ctrl_jump), .is_float(ctrl_is_float), .is_io(ctrl_is_io),
        .wb_src(ctrl_wb_src), .alu_src(ctrl_alu_src), .ext_mode(ctrl_ext_mode)
    );
    
    wire [31:0] imm32;
    imm_extender ext (
        .instr_bits(if_id_instr[25:0]), .ext_mode(ctrl_ext_mode), .imm32(imm32)
    );

    //  ID/EX Pipeline Register Update 
    always @(posedge clk) begin
        if (rst || flush) begin
            id_ex_alu_op    <= 0;
            id_ex_mem_read  <= 0;
            id_ex_mem_write <= 0;
            id_ex_reg_write <= 0;
            id_ex_branch    <= 0;
            id_ex_jump      <= 0;
            id_ex_is_float  <= 0;
            id_ex_is_io     <= 0;
            id_ex_wb_src    <= 0;
            id_ex_alu_src   <= 0;
            id_ex_rs1_data  <= 0;
            id_ex_rs2_data  <= 0;
            id_ex_imm32     <= 0;
            id_ex_rd_addr   <= 0;
            id_ex_rs1_addr  <= 0;
            id_ex_rs2_addr  <= 0;
            id_ex_pc_plus4  <= 0;
        end else if (!stall) begin
            id_ex_alu_op    <= ctrl_alu_op;
            id_ex_mem_read  <= ctrl_mem_read;
            id_ex_mem_write <= ctrl_mem_write;
            id_ex_reg_write <= ctrl_reg_write;
            id_ex_branch    <= ctrl_branch;
            id_ex_jump      <= ctrl_jump;
            id_ex_is_float  <= ctrl_is_float;
            id_ex_is_io     <= ctrl_is_io;
            id_ex_wb_src    <= ctrl_wb_src;
            id_ex_alu_src   <= ctrl_alu_src;
            id_ex_rs1_data  <= regfile_rs1;
            id_ex_rs2_data  <= regfile_rs2;
            id_ex_imm32     <= imm32;
            id_ex_rd_addr   <= rd;
            id_ex_rs1_addr  <= rs1_addr;
            id_ex_rs2_addr  <= rs2_addr;
            id_ex_pc_plus4  <= if_id_pc_plus4;
        end
    end

endmodule
