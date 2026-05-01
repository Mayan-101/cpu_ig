`timescale 1ns / 1ps

module ram_async (
    input wire clk,
    input wire [4:0] addr,
    input wire [31:0] wr_data,
    input wire we,
    output wire [31:0] rd_data
);

    reg [31:0] mem [0:31];

    always @(posedge clk) begin
        if (we) begin
            mem[addr] <= wr_data;
        end
    end

    assign rd_data = mem[addr];

endmodule
