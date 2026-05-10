`include "defines.vh"
`timescale 1ns / 1ps

/**
 * Hazard Detection Unit
 *
 * Detects load-use hazards: when a Load instruction is in the EX stage
 * and a subsequent instruction in the ID stage depends on the value being loaded.
 */
module hazard_detection_unit (
    input  wire [4:0] id_ex_rd_addr,
    input  wire       id_ex_mem_read,
    input  wire [4:0] if_id_rs1_addr,
    input  wire [4:0] if_id_rs2_addr,
    output reg        stall,
    output reg        nop_inject
);

    always @(*) begin
        if ((id_ex_mem_read == 1'b1) && (id_ex_rd_addr != 5'd0) &&
           ((id_ex_rd_addr == if_id_rs1_addr) || (id_ex_rd_addr == if_id_rs2_addr))) begin
            stall = 1'b1;
            nop_inject = 1'b1;
        end else begin
            stall = 1'b0;
            nop_inject = 1'b0;
        end
    end

endmodule
