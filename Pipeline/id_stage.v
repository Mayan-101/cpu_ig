`include "defines.vh"

/*
 * Module: id_stage
 * Description: Instruction Decode stage for RISC-V pipeline.
 *              Extracts fields per standard RISC-V encoding:
 *                opcode = instr[6:0],   rd  = instr[11:7],
 *                funct3 = instr[14:12], rs1 = instr[19:15],
 *                rs2    = instr[24:20], funct7 = instr[31:25]
 */
module id_stage (
    input  wire        clk,
    input  wire        rst,
    input  wire        flush,
    input  wire        stall,

    input  wire [31:0] if_id_instr,
    input  wire [31:0] if_id_pc_plus4,
    input  wire [31:0] regfile_rs1,
    input  wire [31:0] regfile_rs2,

    output wire [4:0]  rs1_addr,
    output wire [4:0]  rs2_addr,

    // Pipeline Register Outputs
    output reg  [6:0]  id_ex_opcode,
    output reg  [2:0]  id_ex_funct3,
    output reg  [6:0]  id_ex_funct7,
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
    output reg  [4:0]  id_ex_rd_addr,
    output reg  [4:0]  id_ex_rs1_addr,
    output reg  [4:0]  id_ex_rs2_addr,
    output reg  [31:0] id_ex_pc_plus4,
    output reg         id_ex_is_reti,
    output reg         id_ex_is_halt
);

    // --- RISC-V Field Extraction ---
    wire [6:0] opcode = if_id_instr[6:0];
    wire [2:0] funct3 = if_id_instr[14:12];
    wire [6:0] funct7 = if_id_instr[31:25];

    // --- Control Unit ---
    wire mem_read, mem_write, reg_write, branch, jump;
    wire is_float, is_io, alu_src, is_reti, is_halt;
    wire [1:0] wb_src;
    wire [2:0] ext_mode;

    control_unit cu (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .mem_read(mem_read), .mem_write(mem_write),
        .reg_write(reg_write), .branch(branch), .jump(jump),
        .is_float(is_float), .is_io(is_io), .wb_src(wb_src),
        .alu_src(alu_src), .ext_mode(ext_mode), .is_reti(is_reti),
        .is_halt(is_halt)
    );

    // --- Immediate Extender ---
    wire [31:0] imm32;
    imm_extender imm_ext (
        .instr(if_id_instr[31:7]),
        .ext_mode(ext_mode),
        .imm32(imm32)
    );

    // --- Register Address Extraction (RISC-V standard positions) ---
    assign rs1_addr = if_id_instr[19:15];
    assign rs2_addr = if_id_instr[24:20];
    wire [4:0] rd_addr_in = if_id_instr[11:7];

    // --- Pipeline Register ---
    always @(posedge clk) begin
        if (rst || flush) begin
            id_ex_opcode    <= 7'd0;
            id_ex_funct3    <= 3'd0;
            id_ex_funct7    <= 7'd0;
            id_ex_mem_read  <= 0;
            id_ex_mem_write <= 0;
            id_ex_reg_write <= 0;
            id_ex_branch    <= 0;
            id_ex_jump      <= 0;
            id_ex_is_float  <= 0;
            id_ex_is_io     <= 0;
            id_ex_wb_src    <= 2'd0;
            id_ex_alu_src   <= 0;
            id_ex_rs1_data  <= 32'd0;
            id_ex_rs2_data  <= 32'd0;
            id_ex_imm32     <= 32'd0;
            id_ex_rd_addr   <= 5'd0;
            id_ex_rs1_addr  <= 5'd0;
            id_ex_rs2_addr  <= 5'd0;
            id_ex_pc_plus4  <= 32'd0;
            id_ex_is_reti   <= 0;
            id_ex_is_halt   <= 0;
        end else if (!stall) begin
            id_ex_opcode    <= opcode;
            id_ex_funct3    <= funct3;
            id_ex_funct7    <= funct7;
            id_ex_mem_read  <= mem_read;
            id_ex_mem_write <= mem_write;
            id_ex_reg_write <= reg_write;
            id_ex_branch    <= branch;
            id_ex_jump      <= jump;
            id_ex_is_float  <= is_float;
            id_ex_is_io     <= is_io;
            id_ex_wb_src    <= wb_src;
            id_ex_alu_src   <= alu_src;
            id_ex_rs1_data  <= regfile_rs1;
            id_ex_rs2_data  <= regfile_rs2;
            id_ex_imm32     <= imm32;
            id_ex_rd_addr   <= rd_addr_in;
            id_ex_rs1_addr  <= rs1_addr;
            id_ex_rs2_addr  <= rs2_addr;
            id_ex_pc_plus4  <= if_id_pc_plus4;
            id_ex_is_reti   <= is_reti;
            id_ex_is_halt   <= is_halt;
        end
    end
endmodule
