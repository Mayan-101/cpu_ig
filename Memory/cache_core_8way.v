`timescale 1ns / 1ps

/**
 * 8-Way Set Associative Cache Core
 */
module cache_core_8way #(
    parameter INDEX_WIDTH = 1,
    parameter TAG_WIDTH = 28,
    parameter DATA_WIDTH = 64
)(
    input  wire clk,
    input  wire rst,
    input  wire [31:0] addr,
    input  wire [DATA_WIDTH-1:0] wr_data,
    input  wire we,
    input  wire re,
    
    output wire [DATA_WIDTH-1:0] rd_data,
    output wire hit,
    output wire [2:0] evict_way,
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

    wire [TAG_WIDTH-1:0] w_rd_tag [0:7];
    wire [DATA_WIDTH-1:0] w_rd_data [0:7];
    wire w_valid [0:7];
    wire w_dirty [0:7];

    wire [7:0] way_hit;
    wire [2:0] hit_way_idx;

    assign way_hit[0] = w_valid[0] && (w_rd_tag[0] == tag);
    assign way_hit[1] = w_valid[1] && (w_rd_tag[1] == tag);
    assign way_hit[2] = w_valid[2] && (w_rd_tag[2] == tag);
    assign way_hit[3] = w_valid[3] && (w_rd_tag[3] == tag);
    assign way_hit[4] = w_valid[4] && (w_rd_tag[4] == tag);
    assign way_hit[5] = w_valid[5] && (w_rd_tag[5] == tag);
    assign way_hit[6] = w_valid[6] && (w_rd_tag[6] == tag);
    assign way_hit[7] = w_valid[7] && (w_rd_tag[7] == tag);
    
    assign hit = |way_hit;
    assign hit_way_idx = way_hit[7] ? 3'd7 : 
                         way_hit[6] ? 3'd6 : 
                         way_hit[5] ? 3'd5 : 
                         way_hit[4] ? 3'd4 : 
                         way_hit[3] ? 3'd3 : 
                         way_hit[2] ? 3'd2 : 
                         way_hit[1] ? 3'd1 : 3'd0;

    assign rd_data = hit ? w_rd_data[hit_way_idx] : w_rd_data[evict_way];
    assign evict_data = w_rd_data[evict_way];

    wire [2:0] target_way = hit ? hit_way_idx : evict_way;

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : ways
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

    // Pseudo-LRU placeholder (just using a simple counter or existing LRU unit if it supports 8 ways)
    // For now, I'll use a simple round-robin or similar if lru_unit doesn't scale.
    // Actually, lru_unit.v seems to be designed for 4 ways.
    
    reg [2:0] rr_counter [0:(1<<INDEX_WIDTH)-1];
    integer j;
    initial begin
        for (j = 0; j < (1<<INDEX_WIDTH); j = j + 1) rr_counter[j] = 3'd0;
    end
    
    always @(posedge clk) begin
        if (rst) begin
             for (j = 0; j < (1<<INDEX_WIDTH); j = j + 1) rr_counter[j] <= 3'd0;
        end else if ((re || we) && !hit) begin
            rr_counter[index] <= rr_counter[index] + 1;
        end
    end
    
    assign evict_way = rr_counter[index];

endmodule
