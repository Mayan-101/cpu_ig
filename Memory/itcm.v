`timescale 1ns / 1ps

/**
 * ITCM (Instruction Tightly Coupled Memory)
 * Size: 16 KB (4K x 32-bit words)
 * Features: Dual-port access for simultaneous instruction fetch and data loading.
 */
module itcm (
    input  wire        clk,
    
    // Port A: Data Interface (Loading/Access)
    input  wire [11:0] addr_a,
    input  wire [31:0] din_a,
    input  wire        we_a,
    output wire [31:0] dout_a,
    
    // Port B: Instruction Interface (Fetch)
    input  wire [11:0] addr_b,
    output wire [31:0] dout_b
);

    reg [31:0] mem [0:4095];

    // Synchronous Write
    always @(posedge clk) begin
        if (we_a) begin
            mem[addr_a] <= din_a;
        end
    end

    // Asynchronous Read (Low Latency)
    assign dout_a = mem[addr_a];
    assign dout_b = mem[addr_b];

    // Simulation Initialization
    integer i;
    initial begin
        for (i = 0; i < 4096; i = i + 1) begin
            mem[i] = 32'd0;
        end
    end

endmodule
