`timescale 1ns / 1ps
`include "defines.vh"

/*
 * Module: alu_top
 * Description: Top-level ALU for RISC-V pipeline. Routes to integer ALU,
 *              Booth multiplier, restoring divider, or FPU based on
 *              opcode/funct3/funct7.
 */
module alu_top (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [6:0]  opcode,
    input  wire [2:0]  funct3,
    input  wire [6:0]  funct7,
    output reg  [31:0] result,
    output reg         done,
    output reg  [31:0] psw_out
);

    // ---- Integer ALU ----
    wire [31:0] int_result;
    wire int_N, int_Z, int_C, int_V;
    alu_int int_alu_inst (
        .a(a), .b(b), .opcode(opcode), .funct3(funct3), .funct7(funct7),
        .result(int_result), .N(int_N), .Z(int_Z), .C(int_C), .V(int_V)
    );

    // ---- Multiplier ----
    wire is_mul_op = (opcode == `OPC_OP) && (funct7 == `F7_MULDIV) &&
                     (funct3 == `F3_MUL || funct3 == `F3_MULH || funct3 == `F3_MULHSU || funct3 == `F3_MULHU);
    
    wire mul_a_signed = (funct3 == `F3_MUL || funct3 == `F3_MULH || funct3 == `F3_MULHSU);
    wire mul_b_signed = (funct3 == `F3_MUL || funct3 == `F3_MULH);

    wire [63:0] mul_prod;
    wire mul_done;
    
    booth_multiplier mul_inst (
        .clk(clk), .rst(rst), .start(start && is_mul_op),
        .a(a), .b(b), 
        .a_signed(mul_a_signed), .b_signed(mul_b_signed),
        .product(mul_prod), .done(mul_done)
    );


    // ---- Divider ----
    wire is_div_op = (opcode == `OPC_OP) && (funct7 == `F7_MULDIV) &&
                     (funct3 == `F3_DIV || funct3 == `F3_DIVU || funct3 == `F3_REM || funct3 == `F3_REMU);
    
    wire is_unsigned_div = (funct3 == `F3_DIVU || funct3 == `F3_REMU);
    
    // Sign management for signed division
    wire sign_a = a[31] && !is_unsigned_div;
    wire sign_b = b[31] && !is_unsigned_div;
    wire [31:0] abs_a = sign_a ? (~a + 1) : a;
    wire [31:0] abs_b = sign_b ? (~b + 1) : b;
    
    wire [31:0] div_quot_raw, div_rem_raw;
    wire div_done, div_zero;
    divider div_inst (
        .clk(clk), .rst(rst), .start(start && is_div_op),
        .dividend(abs_a), .divisor(abs_b),
        .quotient(div_quot_raw), .remainder(div_rem_raw),
        .done(div_done), .div_zero(div_zero)
    );

    // Adjust results for signed division
    // quotient sign = sign_a ^ sign_b
    // remainder sign = sign_a
    wire [31:0] div_quot = (sign_a ^ sign_b) ? (~div_quot_raw + 1) : div_quot_raw;
    wire [31:0] div_rem  = sign_a ? (~div_rem_raw + 1) : div_rem_raw;

    // ---- Output Mux ----
    always @(*) begin
        result  = 32'd0;
        done    = 1'b0;
        psw_out = 32'd0;

        if (is_mul_op) begin
            case (funct3)
                `F3_MUL:    result = mul_prod[31:0];
                `F3_MULH:   result = mul_prod[63:32];
                `F3_MULHSU: result = mul_prod[63:32]; // Note: requires multiplier support
                `F3_MULHU:  result = mul_prod[63:32]; // Note: requires multiplier support
                default:    result = mul_prod[31:0];
            endcase
            done = mul_done;
        end else if (is_div_op) begin
            result = (funct3 == `F3_REM || funct3 == `F3_REMU) ? div_rem : div_quot;
            done = div_done;
            if (div_zero) psw_out[22] = 1'b1;
        end else begin

            // All other integer ops (R-type, I-type, loads, stores, LUI, AUIPC)
            result = int_result;
            psw_out[7] = int_Z;
            psw_out[6] = int_C;
            psw_out[5] = int_V;
            psw_out[4] = int_N;
            if (start) done = 1'b1;
        end
    end
endmodule

