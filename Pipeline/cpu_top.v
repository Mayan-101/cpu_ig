`timescale 1ns / 1ps

module cpu_top (
    input  wire        clk,
    input  wire        rst,
    
    // Instruction Memory Interface
    output wire [31:0] pc,
    input  wire [31:0] instr_in,
    input  wire        icache_hit,
    
    // Data Memory Interface
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wr_data,
    output wire        dmem_we,
    output wire        dmem_re,
    input  wire [31:0] dmem_rd_data,
    input  wire        dcache_ready,
    
    // I/O Interface
    input  wire [31:0] io_data_in,
    
    // System signals
    input  wire        irq,
    output wire        halt_cpu
);

    // Pipeline Registers
    reg [31:0] psw;
    reg [31:0] mtvec, mepc, mstatus;
    reg        int_taken_reg;

    wire [31:0] branch_target;
    wire        take_branch;
    wire [1:0]  pc_src;
    wire        flush_IF, flush_ID;
    wire        stall_haz, nop_inject_haz;
    wire        dc_stall;

    //  [1] Fetch (IF) Stage 
    wire [31:0] pc_next;
    wire [31:0] pc_plus4;
    reg  [31:0] pc_reg;

    assign pc_plus4 = pc_reg + 4;
    assign pc_next = (pc_src == 2'b01) ? branch_target : 
                     (pc_src == 2'b10) ? mtvec : pc_plus4;

    always @(posedge clk or posedge rst) begin
        if (rst) pc_reg <= 32'h0000_0000;
        else if (!(stall_haz || stall_alu)) pc_reg <= pc_next;
    end
    assign pc = pc_reg;


    // IF/ID Pipeline Register
    wire [63:0] if_id_in = {pc_plus4, instr_in};
    wire [63:0] if_id_out;
    pipeline_reg #(.WIDTH(64)) if_id_reg_inst (
        .clk(clk), .rst(rst), .stall(stall_haz || stall_alu), .flush(flush_IF),
        .data_in(if_id_in), .data_out(if_id_out)
    );
    
    wire [31:0] if_id_pc_plus4 = if_id_out[63:32];
    wire [31:0] if_id_instr    = if_id_out[31:0];

    //  [2] Decode (ID) Stage 
    wire [5:0]  opcode_id = if_id_instr[31:26];
    wire [5:0]  rd_id     = if_id_instr[25:20];
    wire [5:0]  rs1_id    = if_id_instr[19:14];
    wire [5:0]  rs2_id    = if_id_instr[13:8];
    
    wire [1:0] ext_mode_id;
    wire [31:0] imm32_id;
    imm_extender ie (
        .instr_bits(if_id_instr[25:0]),
        .ext_mode(ext_mode_id),
        .imm32(imm32_id)
    );

    wire [5:0]  rs1_addr_id = rs1_id;
    wire [5:0]  rs2_addr_id = (branch_id || mem_write_id) ? rd_id : rs2_id;
    wire [31:0] rf_rs1_data, rf_rs2_data;

    // Control Unit
    wire [5:0]  alu_op_id;
    wire        alu_src_id, reg_write_id, mem_read_id, mem_write_id, branch_id, jump_id, is_halt_id, is_io_id, is_reti_id;
    wire [1:0]  wb_src_id;

    control_unit cu (
        .opcode(opcode_id), .funct(if_id_instr[7:0]),
        .alu_op(alu_op_id), .alu_src(alu_src_id), .reg_write(reg_write_id),
        .mem_read(mem_read_id), .mem_write(mem_write_id),
        .branch(branch_id), .jump(jump_id), .is_io(is_io_id),
        .wb_src(wb_src_id), .ext_mode(ext_mode_id),
        .is_reti(is_reti_id)
    );
    assign is_halt_id = (opcode_id == 6'h3F && if_id_instr[7:0] == 8'h00);

    // Interrupt handling
    wire int_taken = irq && psw[31];

    // ID/EX Pipeline Bits (Structural Guard)
    localparam IDX_PC_P4_W = 32, IDX_RS1_D_W = 32, IDX_RS2_D_W = 32, IDX_IMM_W = 32;
    localparam IDX_RS1_A_W = 6,  IDX_RS2_A_W = 6,  IDX_RD_A_W  = 6,  IDX_OP_W  = 6;
    localparam IDX_CTRL_W  = 17; // Sum of all 1-bit and 2-bit flags below
    
    // Total Width = 32*4 + 6*3 + 6 + 17 = 128 + 18 + 6 + 17 = 169? 
    // Wait, let's recount based on the actual packing in line 103:
    // pc_p4(32), rs1_d(32), rs2_d(32), imm(32), rs1_a(6), rs2_a(6), rd_a(6), 
    // alu_op(6), alu_src(1), mem_r(1), mem_w(1), reg_w(1), branch(1), jump(1), is_io(1), wb_src(2),
    // halt(1), reti(1), funct(8)
    // 32+32+32+32+6+6+6 + 6+1+1+1+1+1+1+1+2 + 1+1+8 = 171 bits.

    localparam ID_EX_WIDTH = 171;
    wire [ID_EX_WIDTH-1:0] id_ex_in = {
        if_id_pc_plus4, rf_rs1_data, rf_rs2_data, imm32_id, 
        rs1_addr_id, rs2_addr_id, rd_id, 
        alu_op_id, alu_src_id, mem_read_id, mem_write_id, reg_write_id, 
        branch_id, jump_id, is_io_id, wb_src_id,
        is_halt_id, is_reti_id, if_id_instr[7:0]
    };
    wire [ID_EX_WIDTH-1:0] id_ex_out;
    pipeline_reg #(.WIDTH(ID_EX_WIDTH)) id_ex_reg_inst (
        .clk(clk), .rst(rst), .stall(stall_alu), .flush(flush_ID || nop_inject_haz),
        .data_in(id_ex_in), .data_out(id_ex_out)
    );

    // Unpack ID/EX signals using fixed offsets for safety
    wire [31:0] id_ex_pc_plus4     = id_ex_out[170:139];
    wire [31:0] id_ex_rs1_data     = id_ex_out[138:107];
    wire [31:0] id_ex_rs2_data     = id_ex_out[106:75];
    wire [31:0] id_ex_imm32        = id_ex_out[74:43];
    wire [5:0]  id_ex_rs1_addr     = id_ex_out[42:37];
    wire [5:0]  id_ex_rs2_addr     = id_ex_out[36:31];
    wire [5:0]  id_ex_rd_addr      = id_ex_out[30:25];
    wire [5:0]  id_ex_alu_op       = id_ex_out[24:19];
    wire        id_ex_alu_src      = id_ex_out[18];
    wire        id_ex_mem_read     = id_ex_out[17];
    wire        id_ex_mem_write    = id_ex_out[16];
    wire        id_ex_reg_write    = id_ex_out[15];
    wire        id_ex_branch       = id_ex_out[14];
    wire        id_ex_jump         = id_ex_out[13];
    wire        id_ex_is_io        = id_ex_out[12];
    wire [1:0]  id_ex_wb_src       = id_ex_out[11:10];
    wire        id_ex_is_halt      = id_ex_out[9];
    wire        id_ex_is_reti      = id_ex_out[8];
    wire [7:0]  id_ex_funct        = id_ex_out[7:0];

    //  [3] Execute (EX) Stage 
    wire [1:0] forwardA, forwardB;
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

    wire [31:0] alu_out;
    wire [31:0] psw_out;
    wire alu_done;
    alu_top alu_inst (
        .clk(clk), .rst(rst), .start(1'b1), .a(alu_in_a), .b(alu_in_b), .op(id_ex_alu_op),
        .result(alu_out), .done(alu_done), .psw_out(psw_out)
    );

    // PSW and Context Logic
    always @(posedge clk) begin
        if (rst) begin
            psw <= 32'd0;
            int_taken_reg <= 1'b0;
            mtvec   <= 32'h0000_0000;
            mepc    <= 32'h0000_0000;
            mstatus <= 32'h0000_0000;
        end else begin
            if (dmem_we) begin
                if (dmem_addr == 32'h8000_0000) mtvec   <= dmem_wr_data;
                if (dmem_addr == 32'h8000_0004) mepc    <= dmem_wr_data;
                if (dmem_addr == 32'h8000_0008) mstatus <= dmem_wr_data;
            end

            if (id_ex_alu_op == 6'h3F) begin
                if (id_ex_funct == 8'h08) psw[31] <= 1'b1;
                if (id_ex_funct == 8'h09) psw[31] <= 1'b0;
            end

            if (int_taken) begin
                mepc <= pc; 
                mstatus <= psw;
                psw[31] <= 1'b0; 
                int_taken_reg <= 1'b1;
            end else if (id_ex_is_reti) begin
                psw <= mstatus;
            end
        end
    end

    branch_target_calc btc (
        .pc(id_ex_pc_plus4), .imm32(id_ex_imm32), .valA(valA_fwd), .valB(valB_fwd),
        .opcode(id_ex_alu_op), .branch(id_ex_branch), .jump(id_ex_jump),
        .target(branch_target), .take_branch(take_branch)
    );

    // EX/MEM Pipeline Bits (Structural Guard)
    localparam EX_MEM_WIDTH = 78;
    wire [EX_MEM_WIDTH-1:0] ex_mem_in = {
        alu_out, psw_out[7], valB_fwd, id_ex_rd_addr, 
        id_ex_mem_read, id_ex_mem_write, id_ex_reg_write, id_ex_is_io, id_ex_wb_src,
        id_ex_is_halt
    };
    wire [EX_MEM_WIDTH-1:0] ex_mem_out;
    pipeline_reg #(.WIDTH(EX_MEM_WIDTH)) ex_mem_reg_inst (
        .clk(clk), .rst(rst), .stall(stall_alu), .flush(1'b0),
        .data_in(ex_mem_in), .data_out(ex_mem_out)
    );

    // Unpack EX/MEM signals using fixed offsets for safety
    assign ex_mem_alu_result   = ex_mem_out[77:46];
    wire ex_mem_z_flag         = ex_mem_out[45];
    wire [31:0] ex_mem_wr_data = ex_mem_out[44:13];
    wire [5:0] ex_mem_rd_addr   = ex_mem_out[12:7];
    wire ex_mem_mem_read       = ex_mem_out[6];
    wire ex_mem_mem_write      = ex_mem_out[5];
    wire ex_mem_reg_write      = ex_mem_out[4];
    wire ex_mem_is_io          = ex_mem_out[3];
    wire [1:0] ex_mem_wb_src    = ex_mem_out[2:1];
    wire ex_mem_is_halt        = ex_mem_out[0];

    // Stall Logic
    wire stall_alu = !alu_done && (id_ex_alu_op != 6'h00);
    assign dc_stall = stall_alu || stall_haz;

    //  [4] Memory Access (MEM) Stage 
    assign dmem_addr = ex_mem_alu_result;
    assign dmem_wr_data = ex_mem_wr_data;
    assign dmem_we = ex_mem_mem_write;
    assign dmem_re = ex_mem_mem_read;

    // MEM/WB Pipeline Bits (Structural Guard)
    localparam MEM_WB_WIDTH = 74;
    wire [MEM_WB_WIDTH-1:0] mem_wb_in = {
        ex_mem_alu_result, dmem_rd_data, ex_mem_rd_addr, ex_mem_reg_write, ex_mem_wb_src,
        ex_mem_is_halt
    };
    wire [MEM_WB_WIDTH-1:0] mem_wb_out;
    pipeline_reg #(.WIDTH(MEM_WB_WIDTH)) mem_wb_reg_inst (
        .clk(clk), .rst(rst), .stall(stall_alu), .flush(1'b0),
        .data_in(mem_wb_in), .data_out(mem_wb_out)
    );

    // Unpack MEM/WB signals using fixed offsets for safety
    wire [31:0] mem_wb_alu_result = mem_wb_out[73:42];
    wire [31:0] mem_wb_mem_data   = mem_wb_out[41:10];
    assign mem_wb_rd_addr         = mem_wb_out[9:4];
    assign mem_wb_reg_write       = mem_wb_out[3];
    wire [1:0] mem_wb_wb_src      = mem_wb_out[2:1];
    wire mem_wb_is_halt           = mem_wb_out[0];

    assign halt_cpu = mem_wb_is_halt;

    //  [5] Write-Back (WB) Stage 
    assign rf_wr_data = (mem_wb_wb_src == 2'b01) ? mem_wb_mem_data : mem_wb_alu_result;

    //  Hazard Management and Core Units 
    register_file rf (
        .clk(clk), .rst(rst),
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

    wire bhh_pc_src;
    branch_hazard_handler bhh (
        .take_branch(take_branch), .branch_target(branch_target),
        .pc_src(bhh_pc_src), .flush_IF(flush_IF), .flush_ID(flush_ID)
    );
    assign pc_src = int_taken ? 2'b10 : {1'b0, bhh_pc_src};

endmodule
