`timescale 1ns / 1ps

module interrupt_controller (
    input  wire        clk,
    input  wire        rst,
    input  wire [3:0]  addr,
    input  wire [31:0] wdata,
    input  wire        we,
    input  wire        re,
    output reg  [31:0] rdata,
    input  wire [31:0] irqs, // External IRQ lines
    output wire        irq_out
);
    reg [31:0] ie; // Interrupt Enable
    wire [31:0] ip = irqs; // Pending (direct from wires for now)

    assign irq_out = |(ie & ip);

    always @(posedge clk) begin
        if (rst) ie <= 0;
        else if (we && addr == 4'h0) ie <= wdata;
    end

    always @(*) begin
        case (addr)
            4'h0: rdata = ie;
            4'h4: rdata = ip;
            default: rdata = 32'd0;
        endcase
    end
endmodule
