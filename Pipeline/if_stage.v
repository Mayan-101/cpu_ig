`include "defines.vh"
`timescale 1ns / 1ps

module if_stage (
    input  wire clk,
    input  wire rst,
    
    // PC Interface
    input  wire [31:0] pc,
    
    // I-Cache Interface
    input  wire [31:0] icache_data,
    input  wire icache_hit,
    
    // Control Interface
    input  wire flush,
    
    // Pipeline Register (IF/ID)
    output reg  [31:0] if_id_instr,
    output reg  [31:0] if_id_pc_plus4,
    
    // Hazard/Stall Control
    input  wire stall_in,
    output wire stall_out
);

    assign stall_out = !icache_hit;
    
    wire [31:0] pc_plus4 = pc + 4;

    always @(posedge clk) begin

        if (rst) begin
            if_id_instr <= 32'h00000000; // NOP
            if_id_pc_plus4 <= 32'h00000000;
        end else if (flush) begin
            if_id_instr <= 32'h00000000; // NOP
            if_id_pc_plus4 <= 32'h00000000;
        end else if (!(stall_out || stall_in)) begin
            if_id_instr <= icache_data;
            if_id_pc_plus4 <= pc_plus4;
        end
        // If stalled and not flushed, IF/ID holds its previous value
    end

endmodule
