`include "defines.vh"

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

    // Internal Control / Status Signals
    reg [31:0] psw;
    reg [31:0] mtvec, mepc, mstatus;
    
    wire [31:0] branch_target;
    wire        take_branch;
    wire [1:0]  pc_src;
    wire        flush_IF, flush_ID;
    wire        stall_haz, nop_inject_haz;
    wire        stall_alu;

    //  [1] Fetch (IF) Stage 
    reg  [31:0] pc_reg;
    wire [31:0] pc_plus4 = pc_reg + 4;
    wire [31:0] pc_next = (pc_src == 2'b01) ? branch_target : 
                          (pc_src == 2'b10) ? mtvec : pc_plus4;

    wire cache_stall; // Forward declaration

    // Halt Tracking Shift Register (Bypasses missing internal stage routing)
    reg halt_pipe_1, halt_pipe_2, halt_pipe_3;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            halt_pipe_1 <= 1'b0;
            halt_pipe_2 <= 1'b0;
            halt_pipe_3 <= 1'b0;
        end else if (!pipe_stall) begin
            halt_pipe_1 <= is_halt_id && !flush_ID;
            halt_pipe_2 <= halt_pipe_1 && !flush_ID; // Propagation also needs to be flushable
            halt_pipe_3 <= halt_pipe_2;
        end
    end

    wire pc_stall = (stall_haz == 1'b1) || (stall_alu == 1'b1) || (cache_stall == 1'b1) || 
                    (halt_latch == 1'b1) || (is_halt_id && !flush_ID);
    wire pipe_stall = (stall_alu == 1'b1) || (cache_stall == 1'b1) || (halt_latch == 1'b1);
    
    always @(posedge clk or posedge rst) begin
        if (rst) pc_reg <= 32'h0000_0000;
        else if (!pc_stall) begin
            pc_reg <= pc_next;
            
        end
    end
    assign pc = pc_reg;

    wire [31:0] if_id_instr, if_id_pc_plus4;
    if_stage if_inst (
        .clk(clk), .rst(rst),
        .pc(pc_reg),
        .icache_data(instr_in), .icache_hit(icache_hit),
        .flush(flush_IF),
        .if_id_instr(if_id_instr), .if_id_pc_plus4(if_id_pc_plus4),
        .stall_in(pipe_stall || stall_haz),
        .stall_out()
    );

    //  [2] Decode (ID) Stage 
    wire [31:0] rf_rs1_data, rf_rs2_data;
    wire [5:0]  rs1_addr_id, rs2_addr_id;

    wire [5:0]  id_ex_alu_op;
    wire        id_ex_mem_read, id_ex_mem_write, id_ex_reg_write, id_ex_branch, id_ex_jump;
    wire        id_ex_is_float, id_ex_is_io, id_ex_alu_src;
    wire [1:0]  id_ex_wb_src;
    wire [31:0] id_ex_rs1_data, id_ex_rs2_data, id_ex_imm32, id_ex_pc_plus4;
    wire [5:0]  id_ex_rd_addr, id_ex_rs1_addr, id_ex_rs2_addr;
    wire [7:0]  id_ex_funct;
    wire        id_ex_is_reti;

    id_stage id_inst (
        .clk(clk), .rst(rst), .flush(flush_ID || nop_inject_haz), .stall(pipe_stall),
        .if_id_instr(if_id_instr), .if_id_pc_plus4(if_id_pc_plus4),
        .regfile_rs1(rf_rs1_data), .regfile_rs2(rf_rs2_data),
        .rs1_addr(rs1_addr_id), .rs2_addr(rs2_addr_id),
        .id_ex_alu_op(id_ex_alu_op), .id_ex_mem_read(id_ex_mem_read), .id_ex_mem_write(id_ex_mem_write),
        .id_ex_reg_write(id_ex_reg_write), .id_ex_branch(id_ex_branch), .id_ex_jump(id_ex_jump),
        .id_ex_is_float(id_ex_is_float), .id_ex_is_io(id_ex_is_io), .id_ex_wb_src(id_ex_wb_src),
        .id_ex_alu_src(id_ex_alu_src), .id_ex_rs1_data(id_ex_rs1_data), .id_ex_rs2_data(id_ex_rs2_data),
        .id_ex_imm32(id_ex_imm32), .id_ex_rd_addr(id_ex_rd_addr), .id_ex_rs1_addr(id_ex_rs1_addr),
        .id_ex_rs2_addr(id_ex_rs2_addr), .id_ex_pc_plus4(id_ex_pc_plus4),
        .id_ex_funct(id_ex_funct), .id_ex_is_reti(id_ex_is_reti)
    );

    wire int_taken = (irq == 1'b1) && (psw[31] == 1'b1);
    wire is_halt_id = (if_id_instr[31:26] == `OP_MISC && if_id_instr[7:0] == `FUNCT_HALT);
    

    //  [3] Execute (EX) Stage 
    wire [1:0] forwardA, forwardB;
    wire [31:0] ex_mem_alu_result, ex_mem_wr_data;
    wire [5:0]  ex_mem_rd_addr;
    wire ex_mem_zero, ex_mem_mem_read, ex_mem_mem_write, ex_mem_reg_write, ex_mem_is_io;
    wire [1:0] ex_mem_wb_src;
    wire [31:0] rf_wr_data; 
    wire ex_mem_is_halt; // May be floating depending on ex_stage.v

    ex_stage ex_inst (
        .clk(clk), .rst(rst),
        .id_ex_alu_op(id_ex_alu_op), .id_ex_mem_read(id_ex_mem_read), .id_ex_mem_write(id_ex_mem_write),
        .id_ex_reg_write(id_ex_reg_write), .id_ex_branch(id_ex_branch), .id_ex_jump(id_ex_jump),
        .id_ex_is_float(id_ex_is_float), .id_ex_is_io(id_ex_is_io), .id_ex_wb_src(id_ex_wb_src),
        .id_ex_alu_src(id_ex_alu_src), .id_ex_rs1_data(id_ex_rs1_data), .id_ex_rs2_data(id_ex_rs2_data),
        .id_ex_imm32(id_ex_imm32), .id_ex_rd_addr(id_ex_rd_addr), .id_ex_pc_plus4(id_ex_pc_plus4),
        .fwd_ex_mem_data(ex_mem_mem_read ? dmem_rd_data : (ex_mem_is_io ? io_data_in : ex_mem_alu_result)), .fwd_mem_wb_data(rf_wr_data),
        .forwardA(forwardA), .forwardB(forwardB),
        .stall_in(cache_stall),
        .alu_stall(stall_alu),
        .ex_mem_alu_result(ex_mem_alu_result), .ex_mem_zero(ex_mem_zero),
        .ex_mem_wr_data(ex_mem_wr_data), .ex_mem_rd_addr(ex_mem_rd_addr),
        .ex_mem_mem_read(ex_mem_mem_read), .ex_mem_mem_write(ex_mem_mem_write),
        .ex_mem_reg_write(ex_mem_reg_write), .ex_mem_is_io(ex_mem_is_io), .ex_mem_wb_src(ex_mem_wb_src),
        .ex_mem_is_halt(ex_mem_is_halt),
        .take_branch(take_branch), .branch_target(branch_target)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            psw <= 32'd0;
            mtvec   <= 32'h0000_0000;
            mepc    <= 32'h0000_0000;
            mstatus <= 32'h0000_0000;
        end else if (!cache_stall) begin
            if (dmem_we) begin
                if (dmem_addr == 32'h8000_0000) mtvec   <= dmem_wr_data;
                if (dmem_addr == 32'h8000_0004) mepc    <= dmem_wr_data;
                if (dmem_addr == 32'h8000_0008) mstatus <= dmem_wr_data;
            end
            if (id_ex_alu_op == `OP_MISC) begin
                if (id_ex_funct == `FUNCT_EI) psw[31] <= 1'b1;
                if (id_ex_funct == `FUNCT_DI) psw[31] <= 1'b0;
            end
            if (int_taken) begin
                mepc <= pc; mstatus <= psw; psw[31] <= 1'b0; 
            end
        end
    end

    //  [4] Memory Access (MEM) Stage 
    wire [31:0] mem_wb_alu_result, mem_wb_mem_data;
    wire [5:0]  mem_wb_rd_addr;
    wire mem_wb_reg_write, mem_wb_is_io;
    wire [1:0]  mem_wb_wb_src;
    wire mem_wb_is_halt; // May be floating depending on mem_stage.v

    reg halt_latch;
    always @(posedge clk or posedge rst) begin
        if (rst) halt_latch <= 1'b0;
        // Triggers gracefully whether you hooked up mem_wb_is_halt or not
        else if (mem_wb_is_halt === 1'b1 || halt_pipe_3) halt_latch <= 1'b1; 
    end
    assign halt_cpu = halt_latch;

    mem_stage mem_inst (
        .clk(clk), .rst(rst),
        .ex_mem_alu_result(ex_mem_alu_result), .ex_mem_zero(ex_mem_zero),
        .ex_mem_wr_data(ex_mem_wr_data), .ex_mem_rd_addr(ex_mem_rd_addr),
        .ex_mem_mem_read(ex_mem_mem_read), .ex_mem_mem_write(ex_mem_mem_write),
        .ex_mem_reg_write(ex_mem_reg_write), .ex_mem_is_io(ex_mem_is_io), .ex_mem_wb_src(ex_mem_wb_src),
        .ex_mem_is_halt(ex_mem_is_halt),
        .dcache_data(dmem_rd_data), .dcache_hit(dcache_ready),
        .dcache_addr(dmem_addr), .dcache_wr_data(dmem_wr_data), .dcache_we(dmem_we), .dcache_re(dmem_re),
        .cache_stall(cache_stall),
        .mem_wb_alu_result(mem_wb_alu_result), .mem_wb_mem_data(mem_wb_mem_data),
        .mem_wb_rd_addr(mem_wb_rd_addr), .mem_wb_reg_write(mem_wb_reg_write),
        .mem_wb_wb_src(mem_wb_wb_src), .mem_wb_is_io(mem_wb_is_io),
        .mem_wb_is_halt(mem_wb_is_halt)
    );

    //  [5] Write-Back (WB) Stage 
    wire [5:0]  rf_wr_addr;
    wire        rf_we;



    wb_stage wb_inst (
        .mem_wb_alu_result(mem_wb_alu_result), .mem_wb_mem_data(mem_wb_mem_data),
        .mem_wb_rd_addr(mem_wb_rd_addr), .mem_wb_reg_write(mem_wb_reg_write),
        .mem_wb_wb_src(mem_wb_wb_src), .mem_wb_is_io(mem_wb_is_io),
        .io_data_in(io_data_in),
        .rf_wr_addr(rf_wr_addr), .rf_wr_data(rf_wr_data), .rf_we(rf_we)
    );

    //  Hazard Management and Core Units 
    register_file rf (
        .clk(clk), .rst(rst),
        .rs1_addr(rs1_addr_id), .rs2_addr(rs2_addr_id),
        .rd_addr(rf_wr_addr), .wr_data(rf_wr_data), .we(rf_we),
        .rs1_data(rf_rs1_data), .rs2_data(rf_rs2_data)
    );

    hazard_detection_unit hdu (
        .id_ex_rd_addr(id_ex_rd_addr), .id_ex_mem_read(id_ex_mem_read),
        .if_id_rs1_addr(rs1_addr_id), .if_id_rs2_addr(rs2_addr_id),
        .stall(stall_haz), .nop_inject(nop_inject_haz)
    );

    forwarding_unit fwd (
        .ex_mem_rd_addr(ex_mem_rd_addr), .ex_mem_reg_write(ex_mem_reg_write),
        .mem_wb_rd_addr(rf_wr_addr), .mem_wb_reg_write(rf_we),
        .id_ex_rs1_addr(id_ex_rs1_addr), .id_ex_rs2_addr(id_ex_rs2_addr),
        .forwardA(forwardA), .forwardB(forwardB)
    );

    wire bhh_pc_src;
    branch_hazard_handler bhh (
        .take_branch(take_branch), .branch_target(branch_target),
        .pc_src(bhh_pc_src), .flush_IF(flush_IF), .flush_ID(flush_ID)
    );
    assign pc_src = (int_taken == 1'b1) ? 2'b10 : {1'b0, (bhh_pc_src == 1'b1)};

endmodule
