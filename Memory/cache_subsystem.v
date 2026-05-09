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

    // L1 I-Cache (16 KB, 4-way)
    // INDEX_WIDTH = 9, TAG_WIDTH = 20
    wire l1i_hit, l1i_stall, l1i_mem_req, l1i_mem_we;
    wire [31:0] l1i_rd_data, l1i_mem_addr, l1i_mem_wr_data;
    wire [63:0] l1i_mem_data;
    wire l1i_mem_ready;

    l1_cache #(
        .INDEX_WIDTH(9),
        .TAG_WIDTH(20)
    ) l1i (
        .clk(clk), .reset(rst),
        .addr(addr), .wr_data(32'd0), .we(1'b0), .re(re && is_instr),
        .rd_data(l1i_rd_data), .hit(l1i_hit), .stall(l1i_stall),
        .mem_data(l1i_mem_data), .mem_ready(l1i_mem_ready), .mem_req(l1i_mem_req),
        .mem_we(l1i_mem_we), .mem_addr(l1i_mem_addr), .mem_wr_data(l1i_mem_wr_data)
    );

    // L1 D-Cache (8 KB, 4-way)
    // INDEX_WIDTH = 8, TAG_WIDTH = 21
    wire l1d_hit, l1d_stall, l1d_mem_req, l1d_mem_we;
    wire [31:0] l1d_rd_data, l1d_mem_addr, l1d_mem_wr_data;
    wire [63:0] l1d_mem_data;
    wire l1d_mem_ready;

    l1_cache #(
        .INDEX_WIDTH(8),
        .TAG_WIDTH(21)
    ) l1d (
        .clk(clk), .reset(rst),
        .addr(addr), .wr_data(wr_data), .we(we && !is_instr), .re(re && !is_instr),
        .rd_data(l1d_rd_data), .hit(l1d_hit), .stall(l1d_stall),
        .mem_data(l1d_mem_data), .mem_ready(l1d_mem_ready), .mem_req(l1d_mem_req),
        .mem_we(l1d_mem_we), .mem_addr(l1d_mem_addr), .mem_wr_data(l1d_mem_wr_data)
    );

    // Mux L1 outputs
    assign rd_data = is_instr ? l1i_rd_data : l1d_rd_data;
    assign hit = is_instr ? l1i_hit : l1d_hit;
    
    wire l1_mem_req = is_instr ? l1i_mem_req : l1d_mem_req;
    wire l1_mem_we  = is_instr ? 1'b0 : l1d_mem_we;
    wire [31:0] l1_mem_addr = is_instr ? l1i_mem_addr : l1d_mem_addr;
    wire [31:0] l1_mem_wr_data = is_instr ? 32'd0 : l1d_mem_wr_data;

    // Write-Through Controller for D-Cache
    wire wt_pending, wt_mem_we, wt_mem_ready;
    wire [31:0] wt_mem_addr, wt_mem_data;
    wt_controller wt (
        .clk(clk), .rst(rst), .cache_hit(1'b1),
        .we(l1d_mem_we && l1d_mem_req), .addr(l1d_mem_addr), .data(l1d_mem_wr_data),
        .wt_pending(wt_pending), .mem_ready(wt_mem_ready),
        .mem_we(wt_mem_we), .mem_addr(wt_mem_addr), .mem_data(wt_mem_data)
    );

    // L2 Unified Cache (128 KB, 8-way)
    // We'll use a unified L2 for both I and D misses.
    wire l2_hit, l2_stall, l2_mem_req, l2_mem_we;
    wire [31:0] l2_rd_data, l2_mem_addr, l2_mem_wr_data;
    wire [63:0] l2_line_out;
    
    l2_cache l2_u (
        .clk(clk), .rst(rst),
        .addr(wt_mem_we ? wt_mem_addr : l1_mem_addr),
        .wr_data(wt_mem_data),
        .we(wt_mem_we), .re(l1_mem_req && !l1_mem_we),
        .rd_data(l2_rd_data), .line_out(l2_line_out),
        .hit(l2_hit), .stall(l2_stall),
        .mem_data(mem_data), .mem_ready(mem_ready),
        .mem_req(l2_mem_req), .mem_addr(l2_mem_addr),
        .mem_we(l2_mem_we), .mem_wr_data(l2_mem_wr_data)
    );

    assign l1i_mem_ready = l2_hit && l1i_mem_req;
    assign l1i_mem_data = l2_line_out;
    
    assign l1d_mem_ready = l1d_mem_we ? !wt_pending : (l2_hit && l1d_mem_req);
    assign l1d_mem_data = l2_line_out;
    assign wt_mem_ready = l2_hit && wt_mem_we;

    assign stall = (is_instr ? l1i_stall : l1d_stall) || l2_stall || wt_pending;

    assign mem_req = l2_mem_req;
    assign mem_we = l2_mem_we;
    assign mem_addr = l2_mem_addr;
    assign mem_wr_data = l2_mem_wr_data;

endmodule
