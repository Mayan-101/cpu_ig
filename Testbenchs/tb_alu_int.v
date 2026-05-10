`include "defines.vh"
`timescale 1ns / 1ps

module tb_alu_int;

    reg [31:0] a;
    reg [31:0] b;
    reg [6:0]  opcode;
    reg [2:0]  funct3;
    reg [6:0]  funct7;
    wire [31:0] result;
    wire N, Z, C, V;

    alu_int dut (
        .a(a),
        .b(b),
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .result(result),
        .N(N),
        .Z(Z),
        .C(C),
        .V(V)
    );

    integer errors = 0;

    task check_res;
        input [63:0] name;
        input [31:0] exp_res;
        input exp_N;
        input exp_Z;
        input exp_C;
        input exp_V;
        begin
            #1; // Wait for combinational logic
            if (result !== exp_res || N !== exp_N || Z !== exp_Z || C !== exp_C || V !== exp_V) begin
                $display("ERROR in %s at time %0t:", name, $time);
                $display("  a=0x%h, b=0x%h, op=0x%h, f3=%b, f7=%b", a, b, opcode, funct3, funct7);
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
        errors = 0;
        $display("--- RISC-V Integer ALU Test ---");

        // Test ADD (R-type)
        opcode = `OPC_OP; funct3 = `F3_ADD_SUB; funct7 = `F7_BASE;
        a = 32'd10; b = 32'd15;
        check_res("ADD pos", 32'd25, 0, 0, 0, 0);

        a = 32'hFFFFFFFF; b = 32'd2; // -1 + 2 = 1
        check_res("ADD carry", 32'd1, 0, 0, 1, 0);

        // Test SUB (R-type)
        opcode = `OPC_OP; funct3 = `F3_ADD_SUB; funct7 = 7'b0100000;
        a = 32'd20; b = 32'd5;
        check_res("SUB pos", 32'd15, 0, 0, 0, 0);

        // Test SLT
        opcode = `OPC_OP; funct3 = `F3_SLT; funct7 = `F7_BASE;
        a = 32'hFFFFFFFF; b = 32'd1; // -1 < 1
        check_res("SLT true", 32'd1, 0, 0, 0, 0);

        a = 32'd10; b = 32'd5;
        check_res("SLT false", 32'd0, 0, 1, 0, 0);

        // Test ADDI
        opcode = `OPC_OP_IMM; funct3 = `F3_ADD_SUB; funct7 = 7'b0;
        a = 32'd50; b = 32'd100; // b is immediate
        check_res("ADDI", 32'd150, 0, 0, 0, 0);

        // Test LUI
        opcode = `OPC_LUI; 
        a = 32'd0; b = 32'hABCDE000; // b is imm[31:12]
        check_res("LUI", 32'hABCDE000, 1, 0, 0, 0);

        if (errors == 0)
            $display("tb_alu_int PASSED.");
        else
            $display("tb_alu_int FAILED with %0d errors.", errors);
        $finish;
    end

endmodule
