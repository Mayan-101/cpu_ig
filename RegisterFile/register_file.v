`timescale 1ns / 1ps

module register_file (
    input wire clk,
    input wire rst,
    input wire [5:0] rs1_addr,
    input wire [5:0] rs2_addr,
    input wire [5:0] rd_addr,
    input wire [31:0] wr_data,
    input wire we,
    input wire [1:0] bank_sel,
    output reg [31:0] rs1_data,
    output reg [31:0] rs2_data
);

    // Compute effective physical addresses
    // Addresses 0-7 are banked (mapped to 0-31 based on bank_sel)
    // Addresses 8-33 are absolute (mapped to 8-33 directly)
    wire [5:0] rs1_eff = (rs1_addr < 6'd8) ? {1'b0, bank_sel, rs1_addr[2:0]} : rs1_addr;
    wire [5:0] rs2_eff = (rs2_addr < 6'd8) ? {1'b0, bank_sel, rs2_addr[2:0]} : rs2_addr;
    wire [5:0] rd_eff  = (rd_addr  < 6'd8) ? {1'b0, bank_sel, rd_addr[2:0]}  : rd_addr;

    // Output wires from the 4 banks
    wire [31:0] b_rs1_data [0:3];
    wire [31:0] b_rs2_data [0:3];

    genvar b;
    generate
        for (b = 0; b < 4; b = b + 1) begin : banks
            // Write enable for this bank
            // A bank contains physical addresses b*8 to b*8+7
            // rd_eff[4:3] matches 'b'
            // R0 (logical 0) is hardwired to 0 and read-only
            wire bank_we = we & (rd_eff[4:3] == b) & (rd_eff < 6'd32) & (rd_addr != 6'd0);
            
            reg_bank8 bank_inst (
                .clk(clk),
                .rst(rst),
                .we(bank_we),
                .rs1_addr(rs1_eff[2:0]),
                .rs2_addr(rs2_eff[2:0]),
                .rd_addr(rd_eff[2:0]),
                .wr_data(wr_data),
                .rs1_data(b_rs1_data[b]),
                .rs2_data(b_rs2_data[b])
            );
        end
    endgenerate

    // ACC and B registers
    wire [31:0] acc_q;
    wire [31:0] b_q;

    wire acc_we = we & (rd_eff == 6'd32);
    wire b_we   = we & (rd_eff == 6'd33);

    reg32 acc_reg (
        .clk(clk),
        .rst(rst),
        .we(acc_we),
        .d(wr_data),
        .q(acc_q)
    );

    reg32 b_reg (
        .clk(clk),
        .rst(rst),
        .we(b_we),
        .d(wr_data),
        .q(b_q)
    );

    // Read logic multiplexers with Internal Forwarding (Write-before-Read)
    // R0 is hardwired to 0
    always @(*) begin
        if (rs1_addr == 6'd0) begin
            rs1_data = 32'd0;
        end else if (we && (rd_eff == rs1_eff)) begin
            rs1_data = wr_data;
        end else if (rs1_eff == 6'd32) 
            rs1_data = acc_q;
        else if (rs1_eff == 6'd33) 
            rs1_data = b_q;
        else if (rs1_eff < 6'd32) 
            rs1_data = b_rs1_data[rs1_eff[4:3]];
        else 
            rs1_data = 32'd0;
    end

    always @(*) begin
        if (rs2_addr == 6'd0) begin
            rs2_data = 32'd0;
        end else if (we && (rd_eff == rs2_eff)) begin
            rs2_data = wr_data;
        end else if (rs2_eff == 6'd32) 
            rs2_data = acc_q;
        else if (rs2_eff == 6'd33) 
            rs2_data = b_q;
        else if (rs2_eff < 6'd32) 
            rs2_data = b_rs2_data[rs2_eff[4:3]];
        else 
            rs2_data = 32'd0;
    end

endmodule
