`include "defines.vh"

/*
 * Module: register_file
 * Description: RISC-V standard 32x32-bit register file.
 *              x0 is hardwired to zero. 5-bit address space (x0-x31).
 *              Supports write-before-read forwarding.
 */
module register_file (
    input wire clk,
    input wire rst,
    input wire [4:0] rs1_addr,
    input wire [4:0] rs2_addr,
    input wire [4:0] rd_addr,
    input wire [31:0] wr_data,
    input wire we,
    output reg [31:0] rs1_data,
    output reg [31:0] rs2_data
);

    wire [31:0] reg_q [0:31];

    assign reg_q[0] = 32'd0; // x0 is hardwired to 0

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

    // Read logic with internal forwarding (write-before-read)
    always @(*) begin
        if (rs1_addr == 5'd0)
            rs1_data = 32'd0;
        else if (we && (rd_addr == rs1_addr))
            rs1_data = wr_data;
        else
            rs1_data = reg_q[rs1_addr];
    end

    always @(*) begin
        if (rs2_addr == 5'd0)
            rs2_data = 32'd0;
        else if (we && (rd_addr == rs2_addr))
            rs2_data = wr_data;
        else
            rs2_data = reg_q[rs2_addr];
    end

endmodule
