`timescale 1ns / 1ps

module gpio_top (
    input  wire        clk,
    input  wire        rst,
    input  wire [5:0]  addr,
    input  wire [31:0] wdata,
    input  wire        we,
    input  wire        re,
    output reg  [31:0] rdata,
    
    inout  wire [31:0] pins0,
    inout  wire [31:0] pins1,
    inout  wire [31:0] pins2,
    inout  wire [31:0] pins3
);

    reg [31:0] gpio_out [0:3];
    reg [31:0] gpio_oe  [0:3]; // Output Enable
    wire [31:0] gpio_in [0:3];

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : pin_logic
            assign pins0[i] = gpio_oe[0][i] ? gpio_out[0][i] : 1'bz;
            assign pins1[i] = gpio_oe[1][i] ? gpio_out[1][i] : 1'bz;
            assign pins2[i] = gpio_oe[2][i] ? gpio_out[2][i] : 1'bz;
            assign pins3[i] = gpio_oe[3][i] ? gpio_out[3][i] : 1'bz;

            assign gpio_in[0][i] = pins0[i];
            assign gpio_in[1][i] = pins1[i];
            assign gpio_in[2][i] = pins2[i];
            assign gpio_in[3][i] = pins3[i];
        end
    endgenerate

    always @(posedge clk) begin
        if (rst) begin
            for (integer j = 0; j < 4; j = j + 1) begin
                gpio_out[j] <= 32'd0;
                gpio_oe[j]  <= 32'd0;
            end
        end else if (we) begin
            case (addr[5:4])
                2'b00: begin // GPIO0
                    if (addr[3:2] == 2'b00) gpio_out[0] <= wdata;
                    if (addr[3:2] == 2'b10) gpio_oe[0]  <= wdata;
                end
                2'b01: begin // GPIO1
                    if (addr[3:2] == 2'b00) gpio_out[1] <= wdata;
                    if (addr[3:2] == 2'b10) gpio_oe[1]  <= wdata;
                end
                2'b10: begin // GPIO2
                    if (addr[3:2] == 2'b00) gpio_out[2] <= wdata;
                    if (addr[3:2] == 2'b10) gpio_oe[2]  <= wdata;
                end
                2'b11: begin // GPIO3
                    if (addr[3:2] == 2'b00) gpio_out[3] <= wdata;
                    if (addr[3:2] == 2'b10) gpio_oe[3]  <= wdata;
                end
            endcase
        end
    end

    always @(*) begin
        case (addr[5:4])
            2'b00: begin
                if (addr[3:2] == 2'b00) rdata = gpio_out[0];
                else if (addr[3:2] == 2'b01) rdata = gpio_in[0];
                else if (addr[3:2] == 2'b10) rdata = gpio_oe[0];
                else rdata = 32'd0;
            end
            2'b01: begin
                if (addr[3:2] == 2'b00) rdata = gpio_out[1];
                else if (addr[3:2] == 2'b01) rdata = gpio_in[1];
                else if (addr[3:2] == 2'b10) rdata = gpio_oe[1];
                else rdata = 32'd0;
            end
            2'b10: begin
                if (addr[3:2] == 2'b00) rdata = gpio_out[2];
                else if (addr[3:2] == 2'b01) rdata = gpio_in[2];
                else if (addr[3:2] == 2'b10) rdata = gpio_oe[2];
                else rdata = 32'd0;
            end
            2'b11: begin
                if (addr[3:2] == 2'b00) rdata = gpio_out[3];
                else if (addr[3:2] == 2'b01) rdata = gpio_in[3];
                else if (addr[3:2] == 2'b10) rdata = gpio_oe[3];
                else rdata = 32'd0;
            end
            default: rdata = 32'd0;
        endcase
    end
endmodule
