`include "defines.vh"
`timescale 1ns / 1ps

/**
 * Module: branch_hazard_handler
 * Description: Manages pipeline flushes on branch/jump or interrupt entry.
 */
module branch_hazard_handler (
    input  wire        take_branch,
    input  wire [31:0] branch_target,
    input  wire        int_taken,
    output wire        pc_src,
    output wire        flush_IF,
    output wire        flush_ID
);

    // If branch/jump is taken: set PC source to target
    assign pc_src   = (take_branch == 1'b1);

    // Flush IF and ID stages if a branch is taken OR an interrupt is taken
    assign flush_IF = (take_branch == 1'b1) || (int_taken == 1'b1);
    assign flush_ID = (take_branch == 1'b1) || (int_taken == 1'b1);

endmodule
