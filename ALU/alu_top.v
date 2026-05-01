`timescale 1ns / 1ps

module alu_top (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [5:0]  op,
    output reg  [31:0] result,
    output reg         done,
    output reg  [3:0]  int_flags, // {N, Z, C, V}
    output reg  [2:0]  fp_flags   // {of, uf, z}
);

    // Int ALU
    wire [31:0] int_result;
    wire int_N, int_Z, int_C, int_V;
    alu_int int_alu_inst (
        .a(a), .b(b), .alu_op(op[4:0]),
        .result(int_result), .N(int_N), .Z(int_Z), .C(int_C), .V(int_V)
    );

    // Multiplier
    wire [63:0] mul_prod;
    wire mul_done;
    booth_multiplier mul_inst (
        .clk(clk), .rst(rst), .start(start && (op == 6'b010000)),
        .a(a), .b(b), .product(mul_prod), .done(mul_done)
    );

    // Divider
    wire [31:0] div_quot, div_rem;
    wire div_done, div_zero;
    divider div_inst (
        .clk(clk), .rst(rst), .start(start && (op == 6'b010001)),
        .dividend(a), .divisor(b),
        .quotient(div_quot), .remainder(div_rem),
        .done(div_done), .div_zero(div_zero)
    );

    // FPU
    wire [31:0] fadd_res, fsub_res, fmul_res;
    wire fadd_of, fadd_uf, fsub_of, fsub_uf, fmul_of, fmul_uf;

    float_add_sub fadd_inst (.a(a), .b(b), .op(1'b0), .result(fadd_res), .of_flag(fadd_of), .uf_flag(fadd_uf));
    float_add_sub fsub_inst (.a(a), .b(b), .op(1'b1), .result(fsub_res), .of_flag(fsub_of), .uf_flag(fsub_uf));
    float_mul     fmul_inst (.a(a), .b(b), .result(fmul_res), .of_flag(fmul_of), .uf_flag(fmul_uf));

    always @(*) begin
        // default
        result = 32'd0;
        done = 1'b0;
        int_flags = 4'd0;
        fp_flags = 3'd0;

        if (op[5:4] == 2'b00) begin
            // Int ALU ops
            result = int_result;
            int_flags = {int_N, int_Z, int_C, int_V};
            if (start) done = 1'b1; // combinational
        end else if (op == 6'b010000) begin
            // MUL
            result = mul_prod[31:0];
            done = mul_done;
        end else if (op == 6'b010001) begin
            // DIV
            result = div_quot;
            done = div_done;
        end else if (op == 6'b100000) begin
            // FADD
            result = fadd_res;
            fp_flags = {fadd_of, fadd_uf, (fadd_res == 32'b0)};
            if (start) done = 1'b1;
        end else if (op == 6'b100001) begin
            // FSUB
            result = fsub_res;
            fp_flags = {fsub_of, fsub_uf, (fsub_res == 32'b0)};
            if (start) done = 1'b1;
        end else if (op == 6'b100010) begin
            // FMUL
            result = fmul_res;
            fp_flags = {fmul_of, fmul_uf, (fmul_res == 32'b0)};
            if (start) done = 1'b1;
        end
    end
endmodule
