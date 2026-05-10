`include "defines.vh"
`timescale 1ns / 1ps

module tb_imm_extender;

    reg [31:7] instr;
    reg [2:0] ext_mode;
    wire [31:0] imm32;

    imm_extender dut (
        .instr(instr),
        .ext_mode(ext_mode),
        .imm32(imm32)
    );

    integer pass_count, fail_count;

    task check;
        input [127:0] name;
        input [31:0] expected;
        begin
            #1;
            if (imm32 !== expected) begin
                $display("FAIL: %s | result=%h | expected=%h", name, imm32, expected);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: %s | result=%h", name, imm32);
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        $display("--- RISC-V Immediate Extender Test ---");

        // Test 1: I-type (ADDI x1, x0, 5)
        // imm[11:0] = 5 (0x005)
        // instr[31:20] = 0x005, others don't matter
        instr = 0;
        instr[31:20] = 12'h005;
        ext_mode = 3'b000;
        check("I-type +5", 32'h00000005);

        // Test 2: I-type negative (ADDI x1, x0, -1)
        // imm[11:0] = 0xFFF
        instr = 0;
        instr[31:20] = 12'hFFF;
        ext_mode = 3'b000;
        check("I-type -1", 32'hFFFFFFFF);

        // Test 3: S-type (SW x1, 4(x2))
        // imm = 4 (0x004) -> imm[11:5]=0, imm[4:0]=4
        // instr[31:25] = 0, instr[11:7] = 4
        instr = 0;
        instr[31:25] = 7'b0;
        instr[11:7] = 5'd4;
        ext_mode = 3'b001;
        check("S-type +4", 32'h00000004);

        // Test 4: B-type (BEQ x1, x2, +8)
        // imm = 8 (0x008) -> imm[12]=0, imm[11]=0, imm[10:5]=0, imm[4:1]=4 (0100)
        // instr[31]=0, instr[7]=0, instr[30:25]=0, instr[11:8]=4'b0100
        instr = 0;
        instr[31] = 1'b0;
        instr[7] = 1'b0;
        instr[30:25] = 6'b0;
        instr[11:8] = 4'b0100;
        ext_mode = 3'b010;
        check("B-type +8", 32'h00000008);

        // Test 5: U-type (LUI x1, 0x12345)
        // imm = 0x12345000 -> imm[31:12]=0x12345
        // instr[31:12] = 0x12345
        instr = 0;
        instr[31:12] = 20'h12345;
        ext_mode = 3'b011;
        check("U-type 0x12345", 32'h12345000);

        // Test 6: J-type (JAL x0, +1024)
        // imm = 1024 (0x400) -> imm[20]=0, imm[19:12]=0, imm[11]=0, imm[10:1]=0x200 (10'b10_0000_0000)
        // instr[31]=0, instr[19:12]=0, instr[20]=0, instr[30:21]=0x200
        instr = 0;
        instr[31] = 0;
        instr[19:12] = 8'b0;
        instr[20] = 1'b0;
        instr[30:21] = 10'h200;
        ext_mode = 3'b100;
        check("J-type +1024", 32'h00000400);

        $display("--- Results: %0d PASS, %0d Errors ---", pass_count, fail_count);
        if (fail_count == 0) $display("SUCCESS"); else $display("FAILURE");
        $finish;
    end

endmodule
