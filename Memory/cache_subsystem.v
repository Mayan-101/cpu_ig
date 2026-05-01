`timescale 1ns / 1ps

module cache_subsystem (
    input  wire clk,
    input  wire rst,
    
    // CPU Interface
    input  wire [31:0] addr,
    input  wire [31:0] wr_data,
    input  wire we,
    input  wire re,
    input  wire is_instr,
    output wire [31:0] rd_data,
    output wire hit,
    output wire stall,
    
    // Main Memory Interface
    input  wire [63:0] mem_data,
    input  wire mem_ready,
    output wire mem_req,
    output wire mem_we,
    output wire [31:0] mem_addr,
    output wire [31:0] mem_wr_data
);

    wire l1_hit;
    wire l1_stall;
    wire l1_mem_req;
    wire l1_mem_we;
    wire [31:0] l1_mem_addr;
    wire [31:0] l1_mem_wr_data;
    wire l1_mem_ready;
    wire [63:0] l1_mem_data;

    l1_cache l1 (
        .clk(clk),
        .reset(rst),
        .addr(addr),
        .wr_data(wr_data),
        .we(we),
        .re(re),
        .rd_data(rd_data),
        .hit(l1_hit),
        .stall(l1_stall),
        .mem_data(l1_mem_data),
        .mem_ready(l1_mem_ready),
        .mem_req(l1_mem_req),
        .mem_we(l1_mem_we),
        .mem_addr(l1_mem_addr),
        .mem_wr_data(l1_mem_wr_data)
    );

    wire wt_pending;
    wire wt_mem_we;
    wire [31:0] wt_mem_addr;
    wire [31:0] wt_mem_data;
    wire wt_mem_ready; 
    
    wt_controller wt (
        .clk(clk),
        .rst(rst),
        .cache_hit(1'b1), 
        .we(l1_mem_we && l1_mem_req),
        .addr(l1_mem_addr),
        .data(l1_mem_wr_data),
        .wt_pending(wt_pending),
        .mem_ready(wt_mem_ready),
        .mem_we(wt_mem_we),
        .mem_addr(wt_mem_addr),
        .mem_data(wt_mem_data)
    );

    wire ch_fill_l1;
    wire [63:0] ch_fill_data;
    wire ch_stall;
    wire ch_mem_req;
    wire [31:0] ch_mem_addr;
    
    wire l2i_hit, l2i_stall, l2i_mem_req;
    wire [63:0] l2i_data_out;
    wire [31:0] l2i_mem_addr;
    
    wire l2d_hit, l2d_stall, l2d_mem_req, l2d_mem_we;
    wire [31:0] l2d_rd_data;
    wire [63:0] l2d_line_out;
    wire [31:0] l2d_mem_addr;
    wire [31:0] l2d_mem_wr_data;
    
    wire l2_hit_comb = is_instr ? l2i_hit : l2d_hit;
    wire [63:0] l2_data_comb = is_instr ? l2i_data_out : l2d_line_out;
    
    wire mem_ready_to_ch = mem_ready && (is_instr ? l2i_mem_req : l2d_mem_req);
    
    cache_hierarchy ch (
        .clk(clk),
        .rst(rst),
        .l1_miss(l1_mem_req && !l1_mem_we),
        .l1_addr(l1_mem_addr),
        .fill_l1(ch_fill_l1),
        .fill_data(ch_fill_data),
        .stall_pipeline(ch_stall),
        .l2_hit(l2_hit_comb),
        .l2_data(l2_data_comb),
        .mem_req(ch_mem_req),
        .mem_addr(ch_mem_addr),
        .mem_ready(mem_ready_to_ch),
        .mem_data(mem_data)
    );

    assign l1_mem_ready = l1_mem_we ? !wt_pending : ch_fill_l1;
    assign l1_mem_data = ch_fill_data;
    
    assign stall = l1_stall || (l1_mem_we && wt_pending) || (l1_mem_req && !l1_mem_we && ch_stall);
    assign hit = l1_hit;

    l2_icache l2i (
        .clk(clk),
        .rst(rst),
        .i_addr(ch_mem_addr),
        .re(ch_mem_req && is_instr),
        .instr_data(l2i_data_out),
        .hit(l2i_hit),
        .stall(l2i_stall),
        .mem_data(mem_data),
        .mem_ready(mem_ready),
        .mem_req(l2i_mem_req),
        .mem_addr(l2i_mem_addr)
    );

    l2_dcache l2d (
        .clk(clk),
        .rst(rst),
        .d_addr(wt_mem_we ? wt_mem_addr : ch_mem_addr),
        .wr_data(wt_mem_data),
        .we(wt_mem_we),
        .re(ch_mem_req && !is_instr),
        .rd_data(l2d_rd_data),
        .line_out(l2d_line_out),
        .hit(l2d_hit),
        .stall(l2d_stall),
        .mem_data(mem_data),
        .mem_ready(mem_ready),
        .mem_req(l2d_mem_req),
        .mem_addr(l2d_mem_addr),
        .mem_we(l2d_mem_we),
        .mem_wr_data(l2d_mem_wr_data)
    );

    assign wt_mem_ready = (!l2d_stall && l2d_hit) || (wt_mem_we && mem_ready);

    assign mem_req = is_instr ? l2i_mem_req : l2d_mem_req;
    assign mem_we = is_instr ? 1'b0 : l2d_mem_we;
    assign mem_addr = is_instr ? l2i_mem_addr : l2d_mem_addr;
    assign mem_wr_data = l2d_mem_wr_data;

endmodule
