`include "defines.vh"

/*
 * Module: cpu_top
 * Description: Top-level RISC-V RV32I/M/F pipelined CPU.
 *              5-stage pipeline: IF → ID → EX → MEM → WB
 */
module cpu_top (
    input  wire        clk,
    input  wire        rst,

    // Instruction Bus (IBUS)
    output wire [31:0] ibus_addr,
    input  wire [31:0] ibus_rdata,
    input  wire        ibus_ready,

    // Data Bus (DBUS)
    output wire [31:0] dbus_addr,
    output wire [31:0] dbus_wdata,
    output wire        dbus_we,
    output wire        dbus_re,
    input  wire [31:0] dbus_rdata,
    input  wire        dbus_ready,

    // Peripheral/System Interface
    input  wire [31:0] dbus_io_rdata,
    input  wire        irq,
    output wire        halt_cpu
);

    // CSR outputs (from csr_unit)
    wire [31:0] mtvec, mepc, mstatus;
    wire        trap_taken;
    wire [31:0] trap_pc;
    wire [31:0] csr_rdata;

    wire [31:0] branch_target;
    wire        take_branch;
    wire [1:0]  pc_src;
    wire        flush_IF, flush_ID;
    wire        stall_haz, nop_inject_haz;
    wire        stall_alu;

    // ==== [1] Fetch (IF) Stage ====
    reg  [31:0] pc_reg;
    wire [31:0] pc_plus4 = pc_reg + 4;
    wire [31:0] pc_next = (pc_src == 2'b01) ? branch_target :
                          (pc_src == 2'b10) ? trap_pc : pc_plus4;

    wire cache_stall; // Forward declaration

    wire pc_stall = (stall_haz == 1'b1) || (stall_alu == 1'b1) || (cache_stall == 1'b1) ||
                    (halt_latch == 1'b1) || (ex_mem_is_halt == 1'b1);
    wire pipe_stall = (stall_alu == 1'b1) || (cache_stall == 1'b1) || (halt_latch == 1'b1);

    always @(posedge clk or posedge rst) begin
        if (rst) pc_reg <= 32'h0000_0000;
        else if (!pc_stall) begin
            pc_reg <= pc_next;
        end
    end
    assign ibus_addr = pc_reg;

    wire [31:0] if_id_instr, if_id_pc_plus4;
    if_stage if_inst (
        .clk(clk), .rst(rst),
        .pc(pc_reg),
        .icache_data(ibus_rdata), .icache_hit(ibus_ready),
        .flush(flush_IF),
        .if_id_instr(if_id_instr), .if_id_pc_plus4(if_id_pc_plus4),
        .stall_in(pipe_stall || stall_haz),
        .stall_out()
    );

    // ==== [2] Decode (ID) Stage ====
    wire [31:0] rf_rs1_data, rf_rs2_data;
    wire [4:0]  rs1_addr_id, rs2_addr_id;

    wire [6:0]  id_ex_opcode;
    wire [2:0]  id_ex_funct3;
    wire [6:0]  id_ex_funct7;
    wire        id_ex_mem_read, id_ex_mem_write, id_ex_reg_write, id_ex_branch, id_ex_jump;
    wire        id_ex_is_float, id_ex_is_io, id_ex_alu_src;
    wire [1:0]  id_ex_wb_src;
    wire [31:0] id_ex_rs1_data, id_ex_rs2_data, id_ex_imm32, id_ex_pc_plus4;
    wire [4:0]  id_ex_rd_addr, id_ex_rs1_addr, id_ex_rs2_addr;
    wire        id_ex_is_reti;
    wire        id_ex_is_halt;

    wire [31:0] id_ex_mepc;
    wire [11:0] id_ex_csr_addr;
    wire [4:0]  id_ex_imm5;
    wire        id_ex_ecall;

    id_stage id_inst (
        .clk(clk), .rst(rst), .flush(flush_ID || nop_inject_haz), .stall(pipe_stall),
        .if_id_instr(if_id_instr), .if_id_pc_plus4(if_id_pc_plus4),
        .regfile_rs1(rf_rs1_data), .regfile_rs2(rf_rs2_data),
        .mepc(mepc),
        .rs1_addr(rs1_addr_id), .rs2_addr(rs2_addr_id),
        .id_ex_opcode(id_ex_opcode), .id_ex_funct3(id_ex_funct3), .id_ex_funct7(id_ex_funct7),
        .id_ex_mem_read(id_ex_mem_read), .id_ex_mem_write(id_ex_mem_write),
        .id_ex_reg_write(id_ex_reg_write), .id_ex_branch(id_ex_branch), .id_ex_jump(id_ex_jump),
        .id_ex_is_float(id_ex_is_float), .id_ex_is_io(id_ex_is_io), .id_ex_wb_src(id_ex_wb_src),
        .id_ex_alu_src(id_ex_alu_src), .id_ex_rs1_data(id_ex_rs1_data), .id_ex_rs2_data(id_ex_rs2_data),
        .id_ex_imm32(id_ex_imm32), .id_ex_rd_addr(id_ex_rd_addr), .id_ex_rs1_addr(id_ex_rs1_addr),
        .id_ex_rs2_addr(id_ex_rs2_addr), .id_ex_pc_plus4(id_ex_pc_plus4),
        .id_ex_mepc(id_ex_mepc), .id_ex_csr_addr(id_ex_csr_addr), .id_ex_imm5(id_ex_imm5), .id_ex_ecall(id_ex_ecall),
        .id_ex_is_reti(id_ex_is_reti),
        .id_ex_is_halt(id_ex_is_halt)
    );

    csr_unit csr_inst (
        .clk(clk), .rst(rst),
        .stall(cache_stall),
        .ex_opcode(id_ex_opcode), .ex_funct3(id_ex_funct3), .ex_csr_addr(id_ex_csr_addr),
        .ex_rs1_data(id_ex_rs1_data), .ex_imm5(id_ex_imm5),
        .irq(irq), .ecall_in(id_ex_ecall), .mret_in(id_ex_is_reti),
        .pc_epc(id_ex_pc_plus4 - 4),
        .pc_fec(pc_reg), // Return to current Fetch PC for interrupts
        .ext_we(dbus_we && (dbus_addr[31:12] == 20'h80000)),
        .ext_addr(dbus_addr[11:0]),
        .ext_wdata(dbus_wdata),

        .csr_rdata(csr_rdata),
        .mtvec(mtvec), .mepc(mepc), .mstatus(mstatus),
        .trap_taken(trap_taken), .trap_pc(trap_pc)
    );



    // ==== [3] Execute (EX) Stage ====
    wire [1:0] forwardA, forwardB;
    wire [31:0] ex_mem_alu_result, ex_mem_wr_data;
    wire [4:0]  ex_mem_rd_addr;
    wire ex_mem_zero, ex_mem_mem_read, ex_mem_mem_write, ex_mem_reg_write, ex_mem_is_io;
    wire [1:0] ex_mem_wb_src;
    wire [2:0] ex_mem_funct3;
    wire [31:0] rf_wr_data;
    wire ex_mem_is_halt;
    wire [31:0] ex_mem_pc_plus4;

    ex_stage ex_inst (
        .clk(clk), .rst(rst),
        .id_ex_opcode(id_ex_opcode), .id_ex_funct3(id_ex_funct3), .id_ex_funct7(id_ex_funct7),
        .id_ex_mem_read(id_ex_mem_read), .id_ex_mem_write(id_ex_mem_write),
        .id_ex_reg_write(id_ex_reg_write), .id_ex_branch(id_ex_branch), .id_ex_jump(id_ex_jump),
        .id_ex_is_float(id_ex_is_float), .id_ex_is_io(id_ex_is_io), .id_ex_is_halt(id_ex_is_halt),
        .id_ex_is_reti(id_ex_is_reti),
        .id_ex_wb_src(id_ex_wb_src),
        .id_ex_alu_src(id_ex_alu_src), .id_ex_rs1_data(id_ex_rs1_data), .id_ex_rs2_data(id_ex_rs2_data),
        .id_ex_imm32(id_ex_imm32), .id_ex_mepc(mepc), .id_ex_rd_addr(id_ex_rd_addr), .id_ex_pc_plus4(id_ex_pc_plus4),
        .fwd_ex_mem_data(ex_mem_mem_read ? dbus_rdata : (ex_mem_is_io ? dbus_io_rdata : ex_mem_alu_result)),
        .fwd_mem_wb_data(rf_wr_data),
        .forwardA(forwardA), .forwardB(forwardB),
        .stall_in(cache_stall),
        .alu_stall(stall_alu),
        .ex_mem_alu_result(ex_mem_alu_result), .ex_mem_zero(ex_mem_zero),
        .ex_mem_wr_data(ex_mem_wr_data), .ex_mem_rd_addr(ex_mem_rd_addr),
        .ex_mem_mem_read(ex_mem_mem_read), .ex_mem_mem_write(ex_mem_mem_write),
        .ex_mem_reg_write(ex_mem_reg_write), .ex_mem_is_io(ex_mem_is_io), .ex_mem_wb_src(ex_mem_wb_src),
        .ex_mem_funct3(ex_mem_funct3), .ex_mem_pc_plus4(ex_mem_pc_plus4),
        .ex_mem_is_halt(ex_mem_is_halt),
        .take_branch(take_branch), .branch_target(branch_target)
    );

    // ==== [4] Memory Access (MEM) Stage ====
    wire [31:0] mem_wb_alu_result, mem_wb_mem_data;
    wire [4:0]  mem_wb_rd_addr;
    wire mem_wb_reg_write, mem_wb_is_io;
    wire [1:0]  mem_wb_wb_src;
    wire [31:0] mem_wb_pc_plus4, mem_wb_ext_data;
    wire mem_wb_is_halt;

    reg halt_latch;
    always @(posedge clk or posedge rst) begin
        if (rst) halt_latch <= 1'b0;
        else if (mem_wb_is_halt) halt_latch <= 1'b1;
    end
    assign halt_cpu = halt_latch;

    mem_stage mem_inst (
        .clk(clk), .rst(rst),
        .ex_mem_alu_result(ex_mem_alu_result), .ex_mem_zero(ex_mem_zero),
        .ex_mem_wr_data(ex_mem_wr_data), .ex_mem_rd_addr(ex_mem_rd_addr),
        .ex_mem_pc_plus4(ex_mem_pc_plus4), .ex_mem_ext_data(csr_rdata),
        .ex_mem_mem_read(ex_mem_mem_read), .ex_mem_mem_write(ex_mem_mem_write),
        .ex_mem_reg_write(ex_mem_reg_write), .ex_mem_is_io(ex_mem_is_io), .ex_mem_wb_src(ex_mem_wb_src),
        .ex_mem_funct3(ex_mem_funct3),
        .ex_mem_is_halt(ex_mem_is_halt),
        .dcache_data(dbus_rdata), .dcache_hit(dbus_ready),
        .dcache_addr(dbus_addr), .dcache_wr_data(dbus_wdata), .dcache_we(dbus_we), .dcache_re(dbus_re),
        .cache_stall(cache_stall),
        .mem_wb_alu_result(mem_wb_alu_result), .mem_wb_mem_data(mem_wb_mem_data),
        .mem_wb_rd_addr(mem_wb_rd_addr), .mem_wb_reg_write(mem_wb_reg_write),
        .mem_wb_wb_src(mem_wb_wb_src), .mem_wb_pc_plus4(mem_wb_pc_plus4), .mem_wb_ext_data(mem_wb_ext_data),
        .mem_wb_is_io(mem_wb_is_io),
        .mem_wb_is_halt(mem_wb_is_halt)
    );

    // ==== [5] Write-Back (WB) Stage ====
    wire [4:0]  rf_wr_addr;
    wire        rf_we;

    wb_stage wb_inst (
        .mem_wb_alu_result(mem_wb_alu_result), .mem_wb_mem_data(mem_wb_mem_data),
        .mem_wb_rd_addr(mem_wb_rd_addr), .mem_wb_reg_write(mem_wb_reg_write),
        .mem_wb_wb_src(mem_wb_wb_src), .mem_wb_pc_plus4(mem_wb_pc_plus4),
        .ext_data_in(mem_wb_is_io ? dbus_io_rdata : mem_wb_ext_data),
        .rf_wr_addr(rf_wr_addr), .rf_wr_data(rf_wr_data), .rf_we(rf_we)
    );



    // ==== Hazard Management and Core Units ====
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
        .pc_src(bhh_pc_src), .flush_IF(flush_IF), .flush_ID(flush_ID),
        .int_taken(trap_taken)
    );
    assign pc_src = (trap_taken == 1'b1) ? 2'b10 : {1'b0, (bhh_pc_src == 1'b1)};


endmodule
