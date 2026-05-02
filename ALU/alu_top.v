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
    output reg  [31:0] psw_out
);

    // Int ALU
    wire [31:0] int_result;
    wire int_N, int_Z, int_C, int_V;
    alu_int int_alu_inst (
        .a(a), .b(b), .alu_op(op),
        .result(int_result), .N(int_N), .Z(int_Z), .C(int_C), .V(int_V)
    );

    // Multiplier
    wire [63:0] mul_prod;
    wire mul_done;
    booth_multiplier mul_inst (
        .clk(clk), .rst(rst), .start(start && (op == 6'h0B || op == 6'h0C)),
        .a(a), .b(b), .product(mul_prod), .done(mul_done)
    );

    // Divider
    wire [31:0] div_quot, div_rem;
    wire div_done, div_zero;
    divider div_inst (
        .clk(clk), .rst(rst), .start(start && (op == 6'h0D || op == 6'h0E)),
        .dividend(a), .divisor(b),
        .quotient(div_quot), .remainder(div_rem),
        .done(div_done), .div_zero(div_zero)
    );

    // FPU
    wire [31:0] fadd_res, fsub_res, fmul_res, fitof_res, fftoi_res;
    wire fadd_of, fadd_uf, fsub_of, fsub_uf, fmul_of, fmul_uf;

    float_add_sub fadd_inst (.a(a), .b(b), .op(1'b0), .result(fadd_res), .of_flag(fadd_of), .uf_flag(fadd_uf));
    float_add_sub fsub_inst (.a(a), .b(b), .op(1'b1), .result(fsub_res), .of_flag(fsub_of), .uf_flag(fsub_uf));
    float_mul     fmul_inst (.a(a), .b(b), .result(fmul_res), .of_flag(fmul_of), .uf_flag(fmul_uf));
    float_itof    fitof_inst (.int_in(a), .float_out(fitof_res));
    float_ftoi    fftoi_inst (.float_in(a), .int_out(fftoi_res));

    always @(*) begin
        // default
        result = 32'd0;
        done = 1'b0;
        psw_out = 32'd0;

        if (op[5:4] == 2'b00 || op[5:4] == 2'b01 || op[5:4] == 2'b11) begin
            if (op == 6'h0B || op == 6'h0C) begin
                // MUL / MULH
                result = (op == 6'h0C) ? mul_prod[63:32] : mul_prod[31:0];
                done = mul_done;
            end else if (op == 6'h0D || op == 6'h0E) begin
                // DIV / MOD
                result = (op == 6'h0E) ? div_rem : div_quot;
                done = div_done;
                if (div_zero) psw_out[22] = 1'b1;
            end else begin
                // Int ALU ops
                result = int_result;
                psw_out[7] = int_Z;
                psw_out[6] = int_C;
                psw_out[5] = int_V;
                psw_out[4] = int_N;
                if (start) done = 1'b1; 
            end
        end else if (op[5:4] == 2'b10) begin
            // FPU or Load/Store Address Calc (handled by int_result)
            if (op[3] == 0) begin // LW/SW Address Calc
                result = int_result;
                if (start) done = 1'b1;
            end else begin // FPU
                case (op)
                    6'h28: begin // FADD
                        result = fadd_res;
                        psw_out[21] = fadd_of; psw_out[20] = fadd_uf;
                        psw_out[7]  = (fadd_res == 32'b0);
                        if (start) done = 1'b1;
                    end
                    6'h29: begin // FSUB
                        result = fsub_res;
                        psw_out[21] = fsub_of; psw_out[20] = fsub_uf;
                        psw_out[7]  = (fsub_res == 32'b0);
                        if (start) done = 1'b1;
                    end
                    6'h2A: begin // FMUL
                        result = fmul_res;
                        psw_out[21] = fmul_of; psw_out[20] = fmul_uf;
                        psw_out[7]  = (fmul_res == 32'b0);
                        if (start) done = 1'b1;
                    end
                    6'h2B: begin // FCMP (Stub: sets Z if a == b)
                        result = 32'd0;
                        psw_out[7] = (a == b);
                        if (start) done = 1'b1;
                    end
                    6'h2C: begin // ITOF
                        result = fitof_res;
                        if (start) done = 1'b1;
                    end
                    6'h2D: begin // FTOI
                        result = fftoi_res;
                        if (start) done = 1'b1;
                    end
                    6'h2E: begin // FMOV
                        result = a;
                        if (start) done = 1'b1;
                    end
                endcase
            end
        end
    end
endmodule
