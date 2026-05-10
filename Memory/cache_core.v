`timescale 1ns / 1ps

/**
 * Module: cache_core
 * Description: Parameterized set-associative cache core.
 *              Supports N-way associativity.
 */
module cache_core #(
    parameter INDEX_WIDTH = 1,
    parameter TAG_WIDTH = 28,
    parameter DATA_WIDTH = 64,
    parameter WAYS = 4
)(
    input  wire clk,
    input  wire rst,
    input  wire [31:0] addr,
    input  wire [DATA_WIDTH-1:0] wr_data,
    input  wire we,
    input  wire re,
    
    output wire [DATA_WIDTH-1:0] rd_data,
    output wire hit,
    output wire [$clog2(WAYS)-1:0] evict_way,
    output wire [DATA_WIDTH-1:0] evict_data
);

    wire [TAG_WIDTH-1:0] tag;
    wire [INDEX_WIDTH-1:0] index;
    wire [2:0] offset;
    
    addr_decomp #(
        .ADDR_WIDTH(32),
        .LINE_SIZE(8),
        .NUM_SETS(1 << INDEX_WIDTH)
    ) decomp (
        .addr(addr),
        .tag(tag),
        .index(index),
        .block_offset(offset)
    );

    wire [TAG_WIDTH-1:0] w_rd_tag [0:WAYS-1];
    wire [DATA_WIDTH-1:0] w_rd_data [0:WAYS-1];
    wire w_valid [0:WAYS-1];
    wire w_dirty [0:WAYS-1];

    wire [WAYS-1:0] way_hit;
    reg [$clog2(WAYS)-1:0] hit_way_idx;

    genvar i;
    generate
        for (i = 0; i < WAYS; i = i + 1) begin : hit_logic
            assign way_hit[i] = w_valid[i] && (w_rd_tag[i] == tag);
        end
    endgenerate
    
    assign hit = |way_hit;

    always @(*) begin
        hit_way_idx = 0;
        begin : find_hit
            integer k;
            for (k = 0; k < WAYS; k = k + 1) begin
                if (way_hit[k]) begin
                    hit_way_idx = k[$clog2(WAYS)-1:0];
                    disable find_hit;
                end
            end
        end
    end

    assign rd_data = hit ? w_rd_data[hit_way_idx] : w_rd_data[evict_way];
    assign evict_data = w_rd_data[evict_way];

    wire [$clog2(WAYS)-1:0] target_way = hit ? hit_way_idx : evict_way;

    generate
        for (i = 0; i < WAYS; i = i + 1) begin : ways
            wire way_we = we && (target_way == i);
            
            cache_sram_way #(
                .INDEX_WIDTH(INDEX_WIDTH),
                .TAG_WIDTH(TAG_WIDTH),
                .DATA_WIDTH(DATA_WIDTH)
            ) sram (
                .clk(clk),
                .index(index),
                .wr_tag(tag),
                .wr_data(wr_data),
                .we(way_we),
                .rd_tag(w_rd_tag[i]),
                .rd_data(w_rd_data[i]),
                .valid(w_valid[i]),
                .dirty(w_dirty[i])
            );
        end
    endgenerate

    wire [$clog2(WAYS)-1:0] lru_way_out [0:(1<<INDEX_WIDTH)-1];
    
    generate
        for (i = 0; i < (1<<INDEX_WIDTH); i = i + 1) begin : lru_insts
            wire update_en = (index == i) && ((hit && (re || we)) || (we && !hit));
            
            lru_unit #(
                .WAYS(WAYS)
            ) lru (
                .clk(clk),
                .rst(rst),
                .access_way(target_way),
                .update_en(update_en),
                .lru_way(lru_way_out[i])
            );
        end
    endgenerate

    assign evict_way = lru_way_out[index];

endmodule
