`timescale 1ns / 1ps

module cache_sram_way #(
    parameter INDEX_WIDTH = 1,
    parameter TAG_WIDTH = 28,
    parameter DATA_WIDTH = 64
)(
    input  wire clk,
    input  wire [INDEX_WIDTH-1:0] index,
    input  wire [TAG_WIDTH-1:0] wr_tag,
    input  wire [DATA_WIDTH-1:0] wr_data,
    input  wire we,
    
    output wire [TAG_WIDTH-1:0] rd_tag,
    output wire [DATA_WIDTH-1:0] rd_data,
    output wire valid,
    output wire dirty
);

    localparam NUM_SETS = 1 << INDEX_WIDTH;

    reg [TAG_WIDTH-1:0] tag_array [0:NUM_SETS-1];
    reg [DATA_WIDTH-1:0] data_array [0:NUM_SETS-1];
    reg valid_array [0:NUM_SETS-1];
    reg dirty_array [0:NUM_SETS-1];

    integer i;
    initial begin
        for (i = 0; i < NUM_SETS; i = i + 1) begin
            valid_array[i] = 1'b0;
            dirty_array[i] = 1'b0;
            tag_array[i] = 0;
            data_array[i] = 0;
        end
    end

    always @(posedge clk) begin
        if (we) begin
            tag_array[index]  <= wr_tag;
            data_array[index] <= wr_data;
            valid_array[index] <= 1'b1;
            dirty_array[index] <= 1'b0;
        end
    end

    assign rd_tag = tag_array[index];
    assign rd_data = data_array[index];
    assign valid = valid_array[index];
    assign dirty = dirty_array[index];

endmodule
