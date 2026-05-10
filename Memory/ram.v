`timescale 1ns / 1ps

module ram #(
    parameter ADDR_WIDTH = 23,
    parameter DEPTH = 8388608
)(
    input wire clk,
    input wire we,
    input wire re, // Added for compatibility with testbench
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [31:0] wr_data,
    output wire [31:0] rd_data
);
    reg [31:0] mem [0:DEPTH-1];
    
    always @(posedge clk) begin
        if (we) mem[addr] <= wr_data;
    end
    
    assign rd_data = mem[addr];
endmodule
