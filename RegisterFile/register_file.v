`include "defines.vh"

module register_file (
    input wire clk,
    input wire rst,
    input wire [5:0] rs1_addr,
    input wire [5:0] rs2_addr,
    input wire [5:0] rd_addr,
    input wire [31:0] wr_data,
    input wire we,
    output reg [31:0] rs1_data,
    output reg [31:0] rs2_data
);

    wire [31:0] reg_q [0:31];

    assign reg_q[0] = 32'd0; // R0 is hardwired to 0 and read-only

    genvar i;
    generate
        for (i = 1; i < 32; i = i + 1) begin : gp_regs
            wire reg_we = we & (rd_addr == i);
            reg32 reg_inst (
                .clk(clk),
                .rst(rst),
                .we(reg_we),
                .d(wr_data),
                .q(reg_q[i])
            );
        end
    endgenerate


    // ACC and B registers
    wire [31:0] acc_q;
    wire [31:0] b_q;

    wire acc_we = we & (rd_addr == `REG_ACC);
    wire b_we   = we & (rd_addr == `REG_B);

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
    always @(*) begin
        if (rs1_addr == 6'd0) begin
            rs1_data = 32'd0;
        end else if (we && (rd_addr == rs1_addr)) begin
            rs1_data = wr_data;
        end else if (rs1_addr == `REG_ACC) 
            rs1_data = acc_q;
        else if (rs1_addr == `REG_B) 
            rs1_data = b_q;
        else if (rs1_addr < 6'd32) 
            rs1_data = reg_q[rs1_addr[4:0]];
        else 
            rs1_data = 32'd0;
    end

    always @(*) begin
        if (rs2_addr == 6'd0) begin
            rs2_data = 32'd0;
        end else if (we && (rd_addr == rs2_addr)) begin
            rs2_data = wr_data;
        end else if (rs2_addr == `REG_ACC) 
            rs2_data = acc_q;
        else if (rs2_addr == `REG_B) 
            rs2_data = b_q;
        else if (rs2_addr < 6'd32) 
            rs2_data = reg_q[rs2_addr[4:0]];
        else 
            rs2_data = 32'd0;
    end

endmodule
