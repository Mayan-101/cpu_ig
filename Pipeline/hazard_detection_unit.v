`timescale 1ns / 1ps

/**
 * PHASE 10.1 — Hazard Detection Unit
 * 
 * Detects load-use hazards: when a Load instruction is in the EX stage 
 * and a subsequent instruction in the ID stage depends on the value being loaded.
 * 
 * Inputs:
 * - id_ex_rd_addr: Destination register address of the instruction in EX stage.
 * - id_ex_mem_read: High if the instruction in EX stage is a Load (reads from memory).
 * - if_id_rs1_addr: Source register 1 address of the instruction in ID stage.
 * - if_id_rs2_addr: Source register 2 address of the instruction in ID stage.
 * 
 * Outputs:
 * - stall: Asserted to stall the IF and ID stages.
 * - nop_inject: Asserted to inject a NOP into the EX stage.
 */

module hazard_detection_unit (
    input  wire [5:0] id_ex_rd_addr,
    input  wire       id_ex_mem_read,
    input  wire [5:0] if_id_rs1_addr,
    input  wire [5:0] if_id_rs2_addr,
    output reg        stall,
    output reg        nop_inject
);

    always @(*) begin
        // Check for Load-Use Hazard
        // If the instruction in EX is a Load (mem_read == 1)
        // AND its destination register (rd) is used by the instruction in ID (rs1 or rs2)
        if (id_ex_mem_read && 
           ((id_ex_rd_addr == if_id_rs1_addr) || (id_ex_rd_addr == if_id_rs2_addr))) begin
            stall = 1'b1;
            nop_inject = 1'b1;
        end else begin
            stall = 1'b0;
            nop_inject = 1'b0;
        end
    end

endmodule
