`timescale 1ns / 1ps

/*
 * tb_cycle_tracer.v
 * -----------------
 * Cycle-accurate T-state tracer for the RISC-V pipeline.
 *
 * Wraps system_cache_top and non-intrusively monitors the pipeline via
 * hierarchical references.  For every instruction that retires through the
 * Write-Back (WB) stage the tracer prints:
 *
 *   [RETIRE] CYC=<retire_cycle>  PC=<hex>  OP=<mnemonic>
 *            T-states=<IF-to-WB latency>  extra_stalls=<count>
 *            haz=<load-use stalls>  alu=<multi-cycle stalls>  cache=<cache stalls>
 *
 * At program end a summary histogram is printed showing per-instruction-class
 * totals and averages.
 *
 * USAGE (iverilog):
 *   iverilog -g2012 -I opcode -y ALU -y Memory -y Pipeline \
 *            -y RegisterFile -y Peripherals -y System_Testbenchs \
 *            Testbenchs/tb_cycle_tracer.v -o sim_trace.out
 *   vvp sim_trace.out +PROG=Programs/<name>.hex
 *
 * The output can be piped straight into plot_cycles.py:
 *   vvp sim_trace.out +PROG=Programs/test_rv32i_alu.hex | python Scripts/plot_cycles.py
 */

module tb_cycle_tracer;

    // =========================================================================
    //  Clock / Reset
    // =========================================================================
    reg clk = 0;
    reg rst;
    always #5 clk = ~clk;   // 100 MHz

    // =========================================================================
    //  DUT
    // =========================================================================
    wire halt_cpu;
    system_cache_top uut (
        .clk       (clk),
        .rst       (rst),
        .io_data_out(),
        .io_addr_out(),
        .io_we_out (),
        .stall_cpu (),
        .halt_cpu  (halt_cpu)
    );

    // =========================================================================
    //  Program / data loading
    // =========================================================================
    reg [1023:0] prog_file;
    initial begin
        if ($value$plusargs("PROG=%s", prog_file)) begin
            $readmemh(prog_file, uut.itcm_inst.mem);
            $display("[TRACER] Program loaded: %0s", prog_file);
        end else begin
            $display("[TRACER] WARNING: No +PROG= argument supplied.");
        end
    end

    // =========================================================================
    //  Cycle counter
    // =========================================================================
    integer cycle_cnt;
    initial cycle_cnt = 0;
    always @(posedge clk) if (!rst) cycle_cnt <= cycle_cnt + 1;

    // =========================================================================
    //  Hierarchical pipeline signal aliases
    //  (read-only references into system_cache_top -> cpu_top)
    // =========================================================================
    // IF/ID boundary
    wire [31:0] h_if_id_instr    = uut.cpu.if_id_instr;
    wire [31:0] h_if_id_pc_plus4 = uut.cpu.if_id_pc_plus4;

    // ID/EX boundary
    wire [6:0]  h_id_ex_opcode   = uut.cpu.id_ex_opcode;
    wire [31:0] h_id_ex_pc_plus4 = uut.cpu.id_ex_pc_plus4;

    // EX/MEM boundary
    wire [31:0] h_ex_mem_pc_plus4 = uut.cpu.ex_mem_pc_plus4;

    // MEM/WB boundary  — retirement signals
    wire [31:0] h_mem_wb_pc_plus4  = uut.cpu.mem_wb_pc_plus4;
    wire        h_mem_wb_reg_write  = uut.cpu.mem_wb_reg_write;
    wire [4:0]  h_mem_wb_rd_addr   = uut.cpu.mem_wb_rd_addr;
    wire [1:0]  h_mem_wb_wb_src    = uut.cpu.mem_wb_wb_src;
    wire        h_mem_wb_is_halt   = uut.cpu.mem_wb_is_halt;
    wire [31:0] h_mem_wb_alu_res   = uut.cpu.mem_wb_alu_result;

    // Stall / flush sources
    wire h_stall_haz   = uut.cpu.stall_haz;
    wire h_stall_alu   = uut.cpu.stall_alu;
    wire h_cache_stall = uut.cpu.cache_stall;
    wire h_flush_IF    = uut.cpu.flush_IF;
    wire h_trap_taken  = uut.cpu.trap_taken;

    // =========================================================================
    //  Scoreboard — tracks instructions from IF to WB
    //  Capacity: 16 slots (more than enough for a 5-stage in-order core)
    // =========================================================================
    localparam SB_DEPTH = 16;
    reg [31:0]  sb_pc   [0:SB_DEPTH-1];
    integer     sb_cyc  [0:SB_DEPTH-1];
    reg [6:0]   sb_op   [0:SB_DEPTH-1];
    reg         sb_val  [0:SB_DEPTH-1];

    integer sb_head;  // next write index
    integer sb_tail;  // next read  index

    // Running stall counters (cumulative since last retire)
    integer cum_haz, cum_alu, cum_cache;
    integer snap_haz, snap_alu, snap_cache; // snapshot at last retire

    // =========================================================================
    //  Instruction-class histogram
    // =========================================================================
    // Classes: 0=R-type, 1=I-ALU, 2=LOAD, 3=STORE, 4=BRANCH, 5=JAL, 6=JALR,
    //          7=LUI, 8=AUIPC, 9=SYSTEM, 10=FP, 11=CUSTOM, 12=OTHER
    localparam NC = 13;
    integer hist_count   [0:NC-1];
    integer hist_tstates [0:NC-1];
    integer hist_stalls  [0:NC-1];

    // =========================================================================
    //  Previous MEM/WB values for edge-detection (avoid double-retire)
    // =========================================================================
    reg [31:0] prev_mem_wb_pc;
    reg [31:0] prev_if_id_pc;
    reg [31:0] prev_if_id_instr;

    // =========================================================================
    //  Helpers — opcode → mnemonic string  (combinational, sim-only)
    // =========================================================================
    function [8*8-1:0] op_mnemonic;
        input [6:0] op;
        case (op)
            7'b0110011: op_mnemonic = "R-TYPE  ";
            7'b0010011: op_mnemonic = "I-ALU   ";
            7'b0000011: op_mnemonic = "LOAD    ";
            7'b0100011: op_mnemonic = "STORE   ";
            7'b1100011: op_mnemonic = "BRANCH  ";
            7'b1101111: op_mnemonic = "JAL     ";
            7'b1100111: op_mnemonic = "JALR    ";
            7'b0110111: op_mnemonic = "LUI     ";
            7'b0010111: op_mnemonic = "AUIPC   ";
            7'b1110011: op_mnemonic = "SYSTEM  ";
            7'b1010011: op_mnemonic = "FP-OP   ";
            7'b0001011: op_mnemonic = "CUSTOM  ";
            default:    op_mnemonic = "UNKNOWN ";
        endcase
    endfunction

    function integer op_class;
        input [6:0] op;
        case (op)
            7'b0110011: op_class = 0;
            7'b0010011: op_class = 1;
            7'b0000011: op_class = 2;
            7'b0100011: op_class = 3;
            7'b1100011: op_class = 4;
            7'b1101111: op_class = 5;
            7'b1100111: op_class = 6;
            7'b0110111: op_class = 7;
            7'b0010111: op_class = 8;
            7'b1110011: op_class = 9;
            7'b1010011: op_class = 10;
            7'b0001011: op_class = 11;
            default:    op_class = 12;
        endcase
    endfunction

    function [8*8-1:0] class_name;
        input integer c;
        case (c)
            0:  class_name = "R-TYPE  ";
            1:  class_name = "I-ALU   ";
            2:  class_name = "LOAD    ";
            3:  class_name = "STORE   ";
            4:  class_name = "BRANCH  ";
            5:  class_name = "JAL     ";
            6:  class_name = "JALR    ";
            7:  class_name = "LUI     ";
            8:  class_name = "AUIPC   ";
            9:  class_name = "SYSTEM  ";
            10: class_name = "FP-OP   ";
            11: class_name = "CUSTOM  ";
            default: class_name = "OTHER   ";
        endcase
    endfunction

    // =========================================================================
    //  Initialisation
    // =========================================================================
    integer k;
    initial begin
        sb_head = 0; sb_tail = 0;
        cum_haz = 0; cum_alu = 0; cum_cache = 0;
        snap_haz = 0; snap_alu = 0; snap_cache = 0;
        prev_if_id_pc    = 32'hFFFF_FFFF;
        prev_if_id_instr = 32'hFFFF_FFFF;
        prev_mem_wb_pc   = 32'hFFFF_FFFF;
        for (k = 0; k < SB_DEPTH; k = k+1) begin
            sb_val[k] = 0; sb_pc[k] = 0; sb_cyc[k] = 0; sb_op[k] = 0;
        end
        for (k = 0; k < NC; k = k+1) begin
            hist_count[k] = 0; hist_tstates[k] = 0; hist_stalls[k] = 0;
        end

        $display("=============================================================");
        $display(" RISC-V T-STATE CYCLE TRACER");
        $display("=============================================================");
        $display("%-6s %-10s %-9s %-8s %-8s %-6s %-6s %-6s",
                 "CYC", "PC", "OP[6:0]", "TYPE", "T-STATES", "HAZ", "ALU", "CACHE");
        $display("-------------------------------------------------------------");
    end

    // =========================================================================
    //  Stall accumulation (every cycle after reset)
    // =========================================================================
    always @(posedge clk) begin
        if (!rst) begin
            if (h_stall_haz)   cum_haz   <= cum_haz   + 1;
            if (h_stall_alu)   cum_alu   <= cum_alu   + 1;
            if (h_cache_stall) cum_cache <= cum_cache + 1;
        end
    end

    // =========================================================================
    //  Scoreboard: push when IF/ID captures a new non-NOP instruction
    // =========================================================================
    always @(posedge clk) begin
        if (!rst) begin
            // Detect new issue: IF/ID register changed to a non-NOP instruction
            if ((h_if_id_instr != 32'd0) &&
                (h_if_id_pc_plus4 != prev_if_id_pc)) begin

                sb_pc [sb_head % SB_DEPTH] <= h_if_id_pc_plus4 - 32'd4;
                sb_cyc[sb_head % SB_DEPTH] <= cycle_cnt;
                sb_op [sb_head % SB_DEPTH] <= h_if_id_instr[6:0];
                sb_val[sb_head % SB_DEPTH] <= 1;
                sb_head <= sb_head + 1;
            end
            prev_if_id_pc    <= h_if_id_pc_plus4;
            prev_if_id_instr <= h_if_id_instr;
        end
    end

    // =========================================================================
    //  Scoreboard: pop + report when WB retires any real instruction
    //  Retirement condition: mem_wb_pc_plus4 != 0  (NOP/flush slots have pc=0)
    // =========================================================================
    integer retire_t, extra_stalls;
    integer d_haz, d_alu, d_cache;
    integer r_class;

    always @(posedge clk) begin
        if (!rst && (h_mem_wb_pc_plus4 != 32'd0) &&
                    (h_mem_wb_pc_plus4 != prev_mem_wb_pc)) begin
            // New instruction arrived in WB this cycle
            prev_mem_wb_pc <= h_mem_wb_pc_plus4;

            if (sb_val[sb_tail % SB_DEPTH]) begin
                // T-states: issue was recorded when instr entered IF/ID.
                // retire_t counts from IF/ID capture (+1 for the IF stage itself,
                // +1 for inclusive cycle counting) → perfect = 5 for 5-stage pipeline.
                retire_t     = cycle_cnt - sb_cyc[sb_tail % SB_DEPTH] + 2;
                extra_stalls = (retire_t > 5) ? (retire_t - 5) : 0;

                d_haz   = cum_haz   - snap_haz;
                d_alu   = cum_alu   - snap_alu;
                d_cache = cum_cache - snap_cache;

                $display("%-6d 0x%08h  %7b  %-8s  %-8d  %-6d %-6d %-6d",
                         cycle_cnt,
                         sb_pc [sb_tail % SB_DEPTH],
                         sb_op [sb_tail % SB_DEPTH],
                         op_mnemonic(sb_op[sb_tail % SB_DEPTH]),
                         retire_t,
                         d_haz, d_alu, d_cache);

                r_class = op_class(sb_op[sb_tail % SB_DEPTH]);
                hist_count  [r_class] = hist_count  [r_class] + 1;
                hist_tstates[r_class] = hist_tstates[r_class] + retire_t;
                hist_stalls [r_class] = hist_stalls [r_class] + extra_stalls;

                sb_val[sb_tail % SB_DEPTH] <= 0;
                sb_tail <= sb_tail + 1;
            end

            snap_haz   <= cum_haz;
            snap_alu   <= cum_alu;
            snap_cache <= cum_cache;
        end else begin
            prev_mem_wb_pc <= h_mem_wb_pc_plus4;
        end
    end

    // =========================================================================
    //  Simulation control + end-of-run summary
    // =========================================================================
    integer total_retired;
    integer total_stalls;

    initial begin
        rst = 1;
        #22 rst = 0;

        // Timeout guard
        #100_000_000;  // 100 ms sim time
        $display("\n[TRACER] TIMEOUT");
        $finish;
    end

    always @(posedge clk) begin
        if (halt_cpu) begin
            #10;  // let last retire event fire
            $display("-------------------------------------------------------------");
            $display("\n=============================================================");
            $display(" INSTRUCTION CLASS SUMMARY");
            $display("%-10s %8s %10s %10s %10s",
                     "CLASS", "COUNT", "TOT-T-ST", "AVG-T-ST", "TOT-STALL");
            $display("-------------------------------------------------------------");

            total_retired = 0;
            total_stalls  = 0;

            for (k = 0; k < NC; k = k+1) begin
                if (hist_count[k] > 0) begin
                    $display("%-10s %8d %10d %10d %10d",
                             class_name(k),
                             hist_count[k],
                             hist_tstates[k],
                             hist_tstates[k] / hist_count[k],
                             hist_stalls[k]);
                    total_retired = total_retired + hist_count[k];
                    total_stalls  = total_stalls  + hist_stalls[k];
                end
            end

            $display("-------------------------------------------------------------");
            $display("%-10s %8d %10s %10s %10d",
                     "TOTAL", total_retired, "-", "-", total_stalls);
            $display("=============================================================\n");
            $display("[TRACER] CPI stall overhead: haz=%0d  alu=%0d  cache=%0d",
                     cum_haz, cum_alu, cum_cache);
            $finish;
        end
    end

endmodule
