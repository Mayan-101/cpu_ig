`include "defines.vh"

module id_stage (
    input  wire        clk,
    input  wire        rst,
    input  wire        flush,
    input  wire        stall,
    
    input  wire [31:0] if_id_instr,
    input  wire [31:0] if_id_pc_plus4,
    input  wire [31:0] regfile_rs1,
    input  wire [31:0] regfile_rs2,
    
    output wire [5:0]  rs1_addr,
    output wire [5:0]  rs2_addr,
    
    // Pipeline Register Outputs
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
    output reg  [31:0] id_ex_pc_plus4,
    output reg  [7:0]  id_ex_funct,
    output reg         id_ex_is_reti
);

    wire [5:0] opcode = if_id_instr[31:26];
    
    // Control Unit Signals
    wire [5:0] alu_op;
    wire mem_read, mem_write, reg_write, branch, jump;
    wire is_float, is_io, alu_src, is_reti;
    wire [1:0] wb_src, ext_mode;
    
    control_unit cu (
        .opcode(opcode),
        .funct(if_id_instr[7:0]),
        .alu_op(alu_op), .mem_read(mem_read), .mem_write(mem_write),
        .reg_write(reg_write), .branch(branch), .jump(jump),
        .is_float(is_float), .is_io(is_io), .wb_src(wb_src),
        .alu_src(alu_src), .ext_mode(ext_mode), .is_reti(is_reti), 
        .is_halt() // Handled directly in cpu_top.v
    );

    wire [31:0] imm32;
    imm_extender imm_ext (
        .instr_bits(if_id_instr[25:0]),
        .ext_mode(ext_mode),
        .imm32(imm32)
    );

    // --- DYNAMIC REGISTER EXTRACTION ---
    assign rs1_addr = if_id_instr[19:14];
    
    // Check if the instruction is a Branch (0x30-0x37) or Store (0x21, 0x23, 0x25)
    wire is_b_type = (opcode[5:4] == 2'b11 && opcode[3] == 1'b0);
    wire is_store  = (opcode[5:4] == 2'b10 && opcode[3] == 1'b0 && opcode[0] == 1'b1);
    
    // If Branch or Store, rs2 is mapped to bits [25:20]. Otherwise, [13:8]
    assign rs2_addr = (is_b_type || is_store) ? if_id_instr[25:20] : if_id_instr[13:8];

    // Destination register is always bits [25:20]
    wire [5:0] rd_addr_in = if_id_instr[25:20];

    // Pipeline Register
    always @(posedge clk) begin
        if (rst || flush) begin
            id_ex_alu_op    <= 6'd0;
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
            id_ex_rd_addr   <= 6'd0;
            id_ex_rs1_addr  <= 6'd0;
            id_ex_rs2_addr  <= 6'd0;
            id_ex_pc_plus4  <= 32'd0;
            id_ex_funct     <= 8'd0;
            id_ex_is_reti   <= 0;
        end else if (!stall) begin
            id_ex_alu_op    <= alu_op;
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
            id_ex_rs2_data  <= regfile_rs2; // Holds correctly forwarded data for SW/Branches
            id_ex_imm32     <= imm32;
            id_ex_rd_addr   <= rd_addr_in;
            id_ex_rs1_addr  <= rs1_addr;
            id_ex_rs2_addr  <= rs2_addr;    // Passes correct address to HDU/Forwarding
            id_ex_pc_plus4  <= if_id_pc_plus4;
            id_ex_funct     <= if_id_instr[7:0];
            id_ex_is_reti   <= is_reti;
        end
    end
endmodule
