`timescale 1ns / 1ps

module uart_top (
    input  wire        clk,
    input  wire        rst,
    input  wire [3:0]  addr,
    input  wire [31:0] wdata,
    input  wire        we,
    input  wire        re,
    output reg  [31:0] rdata,
    output reg         tx,
    input  wire        rx,
    output wire        irq
);
    // Simplified UART for now (Mock behavior)
    reg [7:0] tx_data;
    reg [7:0] rx_data;
    reg [31:0] status;
    reg [31:0] ctrl;
    
    assign irq = status[1]; // RX valid interrupt

    always @(posedge clk) begin
        if (rst) begin
            status <= 32'h00000001; // TX Ready bit set
            ctrl   <= 0;
            rx_data <= 0;
            tx <= 1'b1;
        end else if (we) begin
            if (addr == 4'h0) begin
                tx_data <= wdata[7:0];
                // In real UART, this would start shifting
            end else if (addr == 4'hC) begin
                ctrl <= wdata;
            end
        end
    end

    always @(*) begin
        case (addr)
            4'h0: rdata = 32'd0;
            4'h4: rdata = {24'd0, rx_data};
            4'h8: rdata = status;
            4'hC: rdata = ctrl;
            default: rdata = 32'd0;
        endcase
    end
endmodule
