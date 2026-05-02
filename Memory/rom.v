`timescale 1ns / 1ps

module rom #(
    parameter ADDR_WIDTH = 16,
    parameter DEPTH = 65536
)(
    input wire [ADDR_WIDTH-1:0] addr,
    output wire [31:0] data
);
    reg [31:0] mem [0:DEPTH-1];
    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1) mem[i] = 32'd0;
    end
    assign data = mem[addr];
endmodule
