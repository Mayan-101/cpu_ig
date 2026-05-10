`timescale 1ns / 1ps
`include "defines.vh"

/*
 * Module: fpu_top
 * Description: Floating-point unit for RISC-V pipeline. 
 *              Separated from alu_top for better coupling.
 */
module fpu_top (
    input  wire        clk,
    input  wire        rst,
    input  wire        enable,
    input  wire        start,
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [6:0]  funct7,
    output reg  [31:0] result,
    output reg         done,
    output reg  [31:0] psw_out
);

    wire [31:0] fadd_res, fsub_res, fmul_res, fitof_res, fftoi_res;
    wire fadd_of, fadd_uf, fsub_of, fsub_uf, fmul_of, fmul_uf;

    // FPU units are always present but results are muxed. 
    // In a real design, we might clock-gate these based on 'enable'.
    float_add_sub fadd_inst (.a(a), .b(b), .op(1'b0), .result(fadd_res), .of_flag(fadd_of), .uf_flag(fadd_uf));
    float_add_sub fsub_inst (.a(a), .b(b), .op(1'b1), .result(fsub_res), .of_flag(fsub_of), .uf_flag(fsub_uf));
    float_mul     fmul_inst (.a(a), .b(b), .result(fmul_res), .of_flag(fmul_of), .uf_flag(fmul_uf));
    float_itof    fitof_inst (.int_in(a), .float_out(fitof_res));
    float_ftoi    fftoi_inst (.float_in(a), .int_out(fftoi_res));

    always @(*) begin
        result  = 32'd0;
        done    = 1'b0;
        psw_out = 32'd0;

        if (enable) begin
            case (funct7)
                `F7_FADD: begin
                    result = fadd_res;
                    psw_out[21] = fadd_of; psw_out[20] = fadd_uf;
                    psw_out[7]  = (fadd_res == 32'b0);
                    if (start) done = 1'b1;
                end
                `F7_FSUB: begin
                    result = fsub_res;
                    psw_out[21] = fsub_of; psw_out[20] = fsub_uf;
                    psw_out[7]  = (fsub_res == 32'b0);
                    if (start) done = 1'b1;
                end
                `F7_FMUL: begin
                    result = fmul_res;
                    psw_out[21] = fmul_of; psw_out[20] = fmul_uf;
                    psw_out[7]  = (fmul_res == 32'b0);
                    if (start) done = 1'b1;
                end
                `F7_FCMP: begin
                    result = 32'd0;
                    psw_out[7] = (a == b);
                    if (start) done = 1'b1;
                end
                `F7_ITOF: begin
                    result = fitof_res;
                    if (start) done = 1'b1;
                end
                `F7_FTOI: begin
                    result = fftoi_res;
                    if (start) done = 1'b1;
                end
                `F7_FMOV_XW, `F7_FMOV_WX: begin
                    result = a;
                    if (start) done = 1'b1;
                end
                default: begin
                    if (start) done = 1'b1;
                end
            endcase
        end
    end

endmodule
