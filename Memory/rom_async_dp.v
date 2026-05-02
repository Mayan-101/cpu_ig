`timescale 1ns / 1ps

module rom_async_dp #(
    parameter ADDR_WIDTH = 16,
    parameter DEPTH = 65536
)(
    input wire [ADDR_WIDTH-1:0] addr_a,
    output wire [31:0] data_a,
    input wire [ADDR_WIDTH-1:0] addr_b,
    output wire [31:0] data_b
);
    reg [31:0] mem [0:DEPTH-1];
    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1) mem[i] = 32'd0;
    end
    assign data_a = mem[addr_a];
    assign data_b = mem[addr_b];
endmodule
