/*
 * Module: cpu_top
 * Description: Top-level 5-stage RISC pipeline (IF, ID, EX, MEM, WB).
 * Integration: Hazard Detection, Forwarding Unit, Branch Prediction, and Cache Interface.
 */
module cpu_top (
    input  wire        clk,
    input  wire        rst,
    
    // Instruction Memory (ROM) Interface
    output wire [31:0] pc,
    input  wire [31:0] instr_in,
    input  wire        icache_hit,
    
    // Data Memory (RAM) Interface
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wr_data,
    output wire        dmem_we,
    output wire        dmem_re,
    input  wire [31:0] dmem_rd_data,
    input  wire        dcache_ready,
    
    // I/O Peripheral Interface
    input  wire [31:0] io_data_in
);

    //  Control and Hazard Signals 
    wire stall_haz, nop_inject_haz;
    wire [1:0] forwardA, forwardB;
    wire pc_src, flush_IF, flush_ID;
    wire [31:0] branch_target;
    wire take_branch;

    //  [1] Instruction Fetch (IF) Stage 
    wire [31:0] pc_plus4_if = pc + 4;
    wire pc_we = !stall_haz && icache_hit && dcache_ready;

    pc_reg pc_register (
        .clk(clk), .rst(rst),
        .next_pc(pc_src ? branch_target : pc_plus4_if),
        .pc_we(pc_we), .pc(pc)
    );
    
    // IF/ID Pipeline Register
    wire [63:0] if_id_in = {instr_in, pc_plus4_if};
    wire [63:0] if_id_out;
    pipeline_reg #(.WIDTH(64)) if_id_reg_inst (
        .clk(clk), .rst(rst), .stall(stall_haz || !dcache_ready), .flush(flush_IF),
        .data_in(if_id_in), .data_out(if_id_out)
    );
    wire [31:0] if_id_instr = if_id_out[63:32];
    wire [31:0] if_id_pc_plus4 = if_id_out[31:0];

    //  [2] Instruction Decode (ID) Stage 
    wire [5:0] opcode_id = if_id_instr[31:26];
    wire [5:0] rd_id     = if_id_instr[25:20];
    wire [5:0] rs1_id    = if_id_instr[19:14];
    wire [5:0] rs2_id    = if_id_instr[13:8];
    wire [7:0] funct_id  = if_id_instr[7:0];

    wire is_store_id  = (opcode_id == 6'h21 || opcode_id == 6'h23 || opcode_id == 6'h25);
    wire is_branch_id = (opcode_id >= 6'h30 && opcode_id <= 6'h37);
    wire [5:0] rs1_addr_id = rs1_id;
    wire [5:0] rs2_addr_id = (is_store_id || is_branch_id) ? rd_id : rs2_id;

    wire [31:0] rf_rs1_data, rf_rs2_data;
    wire [5:0] alu_op_id;
    wire mem_read_id, mem_write_id, reg_write_id, branch_id, jump_id, is_float_id, is_io_id, alu_src_id;
    wire [1:0] wb_src_id, ext_mode_id;
    
    control_unit cu (
        .opcode(opcode_id), .funct(funct_id),
        .alu_op(alu_op_id), .mem_read(mem_read_id), .mem_write(mem_write_id), .reg_write(reg_write_id),
        .branch(branch_id), .jump(jump_id), .is_float(is_float_id), .is_io(is_io_id),
        .wb_src(wb_src_id), .alu_src(alu_src_id), .ext_mode(ext_mode_id)
    );

    wire [31:0] imm32_id;
    imm_extender ext (
        .instr_bits(if_id_instr[25:0]), .ext_mode(ext_mode_id), .imm32(imm32_id)
    );

    // ID/EX Pipeline Register
    wire [161:0] id_ex_in = {
        alu_op_id, mem_read_id, mem_write_id, reg_write_id, branch_id, jump_id, is_float_id, is_io_id, wb_src_id, alu_src_id,
        rf_rs1_data, rf_rs2_data, imm32_id,
        rd_id, rs1_addr_id, rs2_addr_id,
        if_id_pc_plus4
    };
    wire [161:0] id_ex_out;
    pipeline_reg #(.WIDTH(162)) id_ex_reg_inst (
        .clk(clk), .rst(rst), .stall(!dcache_ready), .flush(flush_ID || nop_inject_haz),
        .data_in(id_ex_in), .data_out(id_ex_out)
    );

    // Unpack ID/EX signals
    wire [5:0] id_ex_alu_op    = id_ex_out[161:156];
    wire id_ex_mem_read        = id_ex_out[155];
    wire id_ex_mem_write       = id_ex_out[154];
    wire id_ex_reg_write       = id_ex_out[153];
    wire id_ex_branch          = id_ex_out[152];
    wire id_ex_jump            = id_ex_out[151];
    wire id_ex_is_float        = id_ex_out[150];
    wire id_ex_is_io           = id_ex_out[149];
    wire [1:0] id_ex_wb_src    = id_ex_out[148:147];
    wire id_ex_alu_src         = id_ex_out[146];
    wire [31:0] id_ex_rs1_data = id_ex_out[145:114];
    wire [31:0] id_ex_rs2_data = id_ex_out[113:82];
    wire [31:0] id_ex_imm32    = id_ex_out[81:50];
    wire [5:0] id_ex_rd_addr   = id_ex_out[49:44];
    wire [5:0] id_ex_rs1_addr  = id_ex_out[43:38];
    wire [5:0] id_ex_rs2_addr  = id_ex_out[37:32];
    wire [31:0] id_ex_pc_plus4 = id_ex_out[31:0];

    //  [3] Execution (EX) Stage 
    wire [31:0] ex_mem_alu_result, rf_wr_data;
    wire [5:0] mem_wb_rd_addr;
    wire mem_wb_reg_write;

    // Forwarding logic for ALU operands
    wire [31:0] valA_fwd = (forwardA == 2'b10) ? ex_mem_alu_result : 
                           (forwardA == 2'b01) ? rf_wr_data : id_ex_rs1_data;
    wire [31:0] valB_fwd = (forwardB == 2'b10) ? ex_mem_alu_result :
                           (forwardB == 2'b01) ? rf_wr_data : id_ex_rs2_data;

    wire [31:0] alu_in_a = valA_fwd;
    wire [31:0] alu_in_b = id_ex_alu_src ? id_ex_imm32 : valB_fwd;

    // Internal ALU Opcode Mapping
    reg [5:0] alu_top_op;
    always @(*) begin
        case (id_ex_alu_op[5:4])
            2'b00: begin // Group 1: R-type
                if (id_ex_alu_op == 6'h0B) alu_top_op = 6'b010000; // MUL
                else if (id_ex_alu_op == 6'h0D) alu_top_op = 6'b010001; // DIV
                else alu_top_op = {2'b00, id_ex_alu_op[3:0] - 4'h1};
            end
            2'b01: begin // Group 2: I-type
                if (id_ex_alu_op == 6'h1A) alu_top_op = 6'b000000; // LUI
                else alu_top_op = {2'b00, id_ex_alu_op[3:0]};
            end
            2'b10: begin // Group 3/4: Mem/Float
                if (id_ex_alu_op[3] == 0) alu_top_op = 6'b000000; // Load/Store -> ADD
                else alu_top_op = {1'b1, 1'b0, id_ex_alu_op[2:0]}; // Float
            end
            2'b11: alu_top_op = 6'b000000; // Default to ADD
            default: alu_top_op = 6'b000000;
        endcase
    end

    wire [31:0] alu_out;
    wire [3:0] alu_flags;
    wire alu_done;
    alu_top alu_inst (
        .clk(clk), .rst(rst), .start(1'b1), .a(alu_in_a), .b(alu_in_b), .op(alu_top_op),
        .result(alu_out), .done(alu_done), .int_flags(alu_flags)
    );

    branch_target_calc btc (
        .pc(id_ex_pc_plus4), .imm32(id_ex_imm32), .valA(valA_fwd), .valB(valB_fwd),
        .opcode(id_ex_alu_op), .branch(id_ex_branch), .jump(id_ex_jump),
        .target(branch_target), .take_branch(take_branch)
    );

    // EX/MEM Pipeline Register
    wire [76:0] ex_mem_in = {
        alu_out, alu_flags[2], valB_fwd, id_ex_rd_addr, 
        id_ex_mem_read, id_ex_mem_write, id_ex_reg_write, id_ex_is_io, id_ex_wb_src
    };
    wire [76:0] ex_mem_out;
    pipeline_reg #(.WIDTH(77)) ex_mem_reg_inst (
        .clk(clk), .rst(rst), .stall(!dcache_ready), .flush(1'b0),
        .data_in(ex_mem_in), .data_out(ex_mem_out)
    );

    // Unpack EX/MEM signals
    assign ex_mem_alu_result  = ex_mem_out[76:45];
    wire [31:0] ex_mem_wr_data= ex_mem_out[43:12];
    wire [5:0] ex_mem_rd_addr  = ex_mem_out[11:6];
    wire ex_mem_mem_read       = ex_mem_out[5];
    wire ex_mem_mem_write      = ex_mem_out[4];
    wire ex_mem_reg_write      = ex_mem_out[3];
    wire [1:0] ex_mem_wb_src    = ex_mem_out[1:0];

    //  [4] Memory Access (MEM) Stage 
    assign dmem_addr = ex_mem_alu_result;
    assign dmem_wr_data = ex_mem_wr_data;
    assign dmem_we = ex_mem_mem_write;
    assign dmem_re = ex_mem_mem_read;

    // MEM/WB Pipeline Register
    wire [72:0] mem_wb_in = {
        ex_mem_alu_result, dmem_rd_data, ex_mem_rd_addr, ex_mem_reg_write, ex_mem_wb_src
    };
    wire [72:0] mem_wb_out;
    pipeline_reg #(.WIDTH(73)) mem_wb_reg_inst (
        .clk(clk), .rst(rst), .stall(!dcache_ready), .flush(1'b0),
        .data_in(mem_wb_in), .data_out(mem_wb_out)
    );

    // Unpack MEM/WB signals
    wire [31:0] mem_wb_alu_result = mem_wb_out[72:41];
    wire [31:0] mem_wb_mem_data   = mem_wb_out[40:9];
    assign mem_wb_rd_addr         = mem_wb_out[8:3];
    assign mem_wb_reg_write       = mem_wb_out[2];
    wire [1:0] mem_wb_wb_src      = mem_wb_out[1:0];

    //  [5] Write-Back (WB) Stage 
    assign rf_wr_data = (mem_wb_wb_src == 2'b01) ? mem_wb_mem_data : mem_wb_alu_result;

    //  Hazard Management and Core Units 
    register_file rf (
        .clk(clk), .rst(rst), .bank_sel(2'b00),
        .rs1_addr(rs1_addr_id), .rs2_addr(rs2_addr_id),
        .rd_addr(mem_wb_rd_addr), .wr_data(rf_wr_data), .we(mem_wb_reg_write),
        .rs1_data(rf_rs1_data), .rs2_data(rf_rs2_data)
    );

    hazard_detection_unit hdu (
        .id_ex_rd_addr(id_ex_rd_addr), .id_ex_mem_read(id_ex_mem_read),
        .if_id_rs1_addr(rs1_addr_id), .if_id_rs2_addr(rs2_addr_id),
        .stall(stall_haz), .nop_inject(nop_inject_haz)
    );

    forwarding_unit fwd (
        .ex_mem_rd_addr(ex_mem_rd_addr), .ex_mem_reg_write(ex_mem_reg_write),
        .mem_wb_rd_addr(mem_wb_rd_addr), .mem_wb_reg_write(mem_wb_reg_write),
        .id_ex_rs1_addr(id_ex_rs1_addr), .id_ex_rs2_addr(id_ex_rs2_addr),
        .forwardA(forwardA), .forwardB(forwardB)
    );

    branch_hazard_handler bhh (
        .take_branch(take_branch), .branch_target(branch_target),
        .pc_src(pc_src), .flush_IF(flush_IF), .flush_ID(flush_ID)
    );

endmodule
