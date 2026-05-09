`timescale 1ns / 1ps

/**
 * DTCM (Data Tightly Coupled Memory)
 * Size: 8 KB (2K x 32-bit words)
 * Features: High-speed, deterministic data access.
 */
module dtcm (
    input  wire        clk,
    input  wire [10:0] addr,
    input  wire [31:0] din,
    input  wire        we,
    output wire [31:0] dout
);

    reg [31:0] mem [0:2047];

    // Synchronous Write
    always @(posedge clk) begin
        if (we) begin
            mem[addr] <= din;
        end
    end

    // Asynchronous Read (Low Latency)
    assign dout = mem[addr];

    // Simulation Initialization
    integer i;
    initial begin
        for (i = 0; i < 2048; i = i + 1) begin
            mem[i] = 32'd0;
        end
    end

endmodule
