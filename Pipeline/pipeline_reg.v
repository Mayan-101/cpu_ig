`timescale 1ns / 1ps

/**
 * PHASE 10.3 — Pipeline Register with Stall / Flush Control
 * 
 * A parameterized pipeline register module with stall and flush capabilities.
 * Reused for IF/ID, ID/EX, EX/MEM, and MEM/WB stages.
 * 
 * Parameters:
 * - WIDTH: The width of the data being registered.
 * 
 * Inputs:
 * - clk: System clock.
 * - rst: System reset (active high).
 * - stall: Stall control (active high). If 1, the register holds its current value.
 * - flush: Flush control (active high). If 1, the register is cleared to 0 (injects NOP).
 * - data_in: Data to be registered.
 * 
 * Outputs:
 * - data_out: Registered data.
 */

module pipeline_reg #(
    parameter WIDTH = 32
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             stall,
    input  wire             flush,
    input  wire [WIDTH-1:0] data_in,
    output reg  [WIDTH-1:0] data_out
);

    always @(posedge clk) begin
        if (rst || flush) begin
            data_out <= {WIDTH{1'b0}};
        end else if (!stall) begin
            data_out <= data_in;
        end
        // If stall is 1, data_out implicitly holds its value.
    end

endmodule
