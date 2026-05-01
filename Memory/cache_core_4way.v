`timescale 1ns / 1ps

module cache_core_4way #(
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
    output wire [1:0] evict_way,
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

    wire [TAG_WIDTH-1:0] w_rd_tag [0:3];
    wire [DATA_WIDTH-1:0] w_rd_data [0:3];
    wire w_valid [0:3];
    wire w_dirty [0:3];

    wire [3:0] way_hit;
    wire [1:0] hit_way_idx;

    assign way_hit[0] = w_valid[0] && (w_rd_tag[0] == tag);
    assign way_hit[1] = w_valid[1] && (w_rd_tag[1] == tag);
    assign way_hit[2] = w_valid[2] && (w_rd_tag[2] == tag);
    assign way_hit[3] = w_valid[3] && (w_rd_tag[3] == tag);
    
    assign hit = |way_hit;
    assign hit_way_idx = way_hit[3] ? 2'd3 : 
                         way_hit[2] ? 2'd2 : 
                         way_hit[1] ? 2'd1 : 2'd0;

    assign rd_data = hit ? w_rd_data[hit_way_idx] : w_rd_data[evict_way];
    assign evict_data = w_rd_data[evict_way];

    wire [1:0] target_way = hit ? hit_way_idx : evict_way;

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : ways
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

    wire [1:0] lru_way_out [0:(1<<INDEX_WIDTH)-1];
    
    generate
        for (i = 0; i < (1<<INDEX_WIDTH); i = i + 1) begin : lru_insts
            wire update_en = (index == i) && ((hit && (re || we)) || (we && !hit));
            
            lru_unit lru (
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
