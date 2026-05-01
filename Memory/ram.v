`timescale 1ns / 1ps

module ram (
    input wire clk,
    input wire [4:0] addr,
    input wire [31:0] wr_data,
    input wire we,
    input wire re,
    output reg [31:0] rd_data
);

    // 32 words x 32 bits (128 B)
    reg [31:0] mem [0:31];

    always @(posedge clk) begin
        if (we) begin
            mem[addr] <= wr_data;
        end
        if (re) begin
            rd_data <= mem[addr];
        end
    end

endmodule
