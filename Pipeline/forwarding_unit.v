`timescale 1ns / 1ps

/**
 * PHASE 10.2 — Forwarding Unit
 * 
 * Generates MUX select signals for EX-EX and MEM-EX forwarding to resolve RAW hazards.
 */
module forwarding_unit (
    input  wire [5:0] ex_mem_rd_addr,
    input  wire       ex_mem_reg_write,
    input  wire [5:0] mem_wb_rd_addr,
    input  wire       mem_wb_reg_write,
    input  wire [5:0] id_ex_rs1_addr,
    input  wire [5:0] id_ex_rs2_addr,
    output reg  [1:0] forwardA,
    output reg  [1:0] forwardB
);

    always @(*) begin
        //  Forwarding for Source A 
        
        // 1. EX Hazard (Priority 1)
        if (ex_mem_reg_write && (ex_mem_rd_addr != 6'd0) && (ex_mem_rd_addr == id_ex_rs1_addr)) begin
            forwardA = 2'b10;
        end
        // 2. MEM Hazard (Priority 2)
        else if (mem_wb_reg_write && (mem_wb_rd_addr != 6'd0) && (mem_wb_rd_addr == id_ex_rs1_addr)) begin
            forwardA = 2'b01;
        end
        // 3. No Hazard
        else begin
            forwardA = 2'b00;
        end

        //  Forwarding for Source B 
        
        // 1. EX Hazard (Priority 1)
        if (ex_mem_reg_write && (ex_mem_rd_addr != 6'd0) && (ex_mem_rd_addr == id_ex_rs2_addr)) begin
            forwardB = 2'b10;
        end
        // 2. MEM Hazard (Priority 2)
        else if (mem_wb_reg_write && (mem_wb_rd_addr != 6'd0) && (mem_wb_rd_addr == id_ex_rs2_addr)) begin
            forwardB = 2'b01;
        end
        // 3. No Hazard
        else begin
            forwardB = 2'b00;
        end
    end

endmodule
