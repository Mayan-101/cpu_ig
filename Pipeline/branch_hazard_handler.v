`include "defines.vh"
`timescale 1ns / 1ps

/**
 * PHASE 10.4 — Branch Hazard Handler & Pipeline Flush
 */
module branch_hazard_handler (
    input  wire        take_branch,
    input  wire [31:0] branch_target,
    output wire        pc_src,
    output wire        flush_IF,
    output wire        flush_ID
);

    // If branch is taken:
    // 1. Set PC source to the branch target
    // 2. Flush the next two instructions already in the pipeline (IF and ID stages)
    assign pc_src   = (take_branch == 1'b1);
    assign flush_IF = (take_branch == 1'b1);
    assign flush_ID = (take_branch == 1'b1);

endmodule
