`timescale 1ns / 1ps

module pc_reg (
    input  wire clk,
    input  wire rst,
    input  wire [31:0] next_pc,
    input  wire pc_we,
    output reg  [31:0] pc
);

    always @(posedge clk) begin
        if (rst) begin
            pc <= 32'h00000000;
        end else if (pc_we) begin
            pc <= next_pc;
        end
    end

endmodule
