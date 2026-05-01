`timescale 1ns / 1ps

module tb_alu_int;

    reg [31:0] a;
    reg [31:0] b;
    reg [4:0]  alu_op;
    wire [31:0] result;
    wire N, Z, C, V;

    alu_int dut (
        .a(a),
        .b(b),
        .alu_op(alu_op),
        .result(result),
        .N(N),
        .Z(Z),
        .C(C),
        .V(V)
    );

    // ALU Opcodes
    localparam OP_ADD  = 5'b00000;
    localparam OP_SUB  = 5'b00001;
    localparam OP_AND  = 5'b00010;
    localparam OP_OR   = 5'b00011;
    localparam OP_XOR  = 5'b00100;
    localparam OP_NOR  = 5'b00101;
    localparam OP_LSL  = 5'b00110;
    localparam OP_LSR  = 5'b00111;
    localparam OP_ASR  = 5'b01000;
    localparam OP_ROR  = 5'b01001;
    localparam OP_SLT  = 5'b01010;
    localparam OP_SLTU = 5'b01011;

    integer errors = 0;

    task check_res;
        input [31:0] exp_res;
        input exp_N;
        input exp_Z;
        input exp_C;
        input exp_V;
        begin
            #1; // Wait a bit for combinational logic
            if (result !== exp_res || N !== exp_N || Z !== exp_Z || C !== exp_C || V !== exp_V) begin
                $display("ERROR at time %0t:", $time);
                $display("  a=0x%h, b=0x%h, op=0x%h", a, b, alu_op);
                $display("  result=0x%h (exp: 0x%h)", result, exp_res);
                $display("  N=%b (exp: %b)", N, exp_N);
                $display("  Z=%b (exp: %b)", Z, exp_Z);
                $display("  C=%b (exp: %b)", C, exp_C);
                $display("  V=%b (exp: %b)", V, exp_V);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        // Test ADD
        // positive result
        a = 32'd10; b = 32'd15; alu_op = OP_ADD;
        check_res(32'd25, 0, 0, 0, 0);

        // zero result
        a = 32'd0; b = 32'd0; alu_op = OP_ADD;
        check_res(32'd0, 0, 1, 0, 0);

        // negative result
        a = 32'hFFFFFFFF; b = 32'd2; alu_op = OP_ADD; // -1 + 2 = 1 (pos) with carry out
        check_res(32'd1, 0, 0, 1, 0);

        a = 32'hFFFFFFFF; b = 32'hFFFFFFFF; alu_op = OP_ADD; // -1 + -1 = -2
        check_res(32'hFFFFFFFE, 1, 0, 1, 0);

        // overflow result
        a = 32'h7FFFFFFF; b = 32'd1; alu_op = OP_ADD;
        check_res(32'h80000000, 1, 0, 0, 1);

        // Test SUB
        // positive result
        a = 32'd20; b = 32'd5; alu_op = OP_SUB;
        check_res(32'd15, 0, 0, 0, 0);

        // zero result
        a = 32'd5; b = 32'd5; alu_op = OP_SUB;
        check_res(32'd0, 0, 1, 0, 0);

        // negative result
        a = 32'd5; b = 32'd10; alu_op = OP_SUB;
        check_res(32'hFFFFFFFB, 1, 0, 1, 0); // 5 - 10 = -5, borrow=1

        // overflow result
        a = 32'h80000000; b = 32'd1; alu_op = OP_SUB;
        check_res(32'h7FFFFFFF, 0, 0, 0, 1);

        // SLT
        a = 32'd5; b = 32'd10; alu_op = OP_SLT;
        check_res(32'd1, 0, 0, 1, 0);

        if (errors == 0)
            $display("tb_alu_int PASSED.");
        else
            $display("tb_alu_int FAILED with %0d errors.", errors);
        $finish;
    end

endmodule
