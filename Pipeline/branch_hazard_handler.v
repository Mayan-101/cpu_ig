`timescale 1ns / 1ps

/**
 * PHASE 10.4 — Branch Hazard Handler & Pipeline Flush
 * 
 * Handles control hazards when a branch is taken. 
 * If a branch is taken (detected in EX stage), the instructions in the 
 * IF and ID stages must be flushed to prevent them from executing.
 * 
 * Inputs:
 * - take_branch: Asserted by the EX stage if a branch condition is met or for Jumps.
 * - branch_target: The calculated destination address of the branch/jump.
 * 
 * Outputs:
 * - pc_src: Selects the branch target as the next PC value (1) or PC+4 (0).
 * - flush_IF: Asserted to clear the IF/ID pipeline register.
 * - flush_ID: Asserted to clear the ID/EX pipeline register.
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
    assign pc_src   = take_branch;
    assign flush_IF = take_branch;
    assign flush_ID = take_branch;

endmodule
