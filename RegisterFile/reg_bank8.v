/*
 * Module: reg_bank8
 * Description: 8-register bank with dual asynchronous read and single synchronous write ports.
 */
module reg_bank8 (
    input  wire        clk,
    input  wire        rst,
    input  wire        we,
    input  wire [2:0]  rs1_addr,
    input  wire [2:0]  rs2_addr,
    input  wire [2:0]  rd_addr,
    input  wire [31:0] wr_data,
    output reg  [31:0] rs1_data,
    output reg  [31:0] rs2_data
);

    wire [31:0] q_out [0:7];
    wire [7:0]  we_dec;

    //  Register Array Instantiation 
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : bank
            assign we_dec[i] = we & (rd_addr == i);
            reg32 r (
                .clk(clk), .rst(rst), .we(we_dec[i]),
                .d(wr_data), .q(q_out[i])
            );
        end
    endgenerate

    //  Combinational Read Ports 
    always @(*) begin
        rs1_data = q_out[rs1_addr];
        rs2_data = q_out[rs2_addr];
    end

endmodule
