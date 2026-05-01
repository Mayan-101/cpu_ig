`timescale 1ns / 1ps

module addr_decomp #(
    parameter ADDR_WIDTH = 32,
    parameter LINE_SIZE = 8,
    parameter NUM_SETS = 2
)(
    input  wire [ADDR_WIDTH-1:0] addr,
    output wire [(ADDR_WIDTH - $clog2(NUM_SETS) - $clog2(LINE_SIZE)) - 1 : 0] tag,
    output wire [$clog2(NUM_SETS)-1:0] index,
    output wire [$clog2(LINE_SIZE)-1:0] block_offset
);

    localparam Ob = $clog2(LINE_SIZE);
    localparam Ib = $clog2(NUM_SETS);
    localparam Tb = ADDR_WIDTH - Ib - Ob;

    assign block_offset = addr[Ob-1:0];
    assign index = addr[Ob+Ib-1:Ob];
    assign tag = addr[ADDR_WIDTH-1:Ob+Ib];

endmodule
