`include "defines.vh"
`timescale 1ns / 1ps

module tb_branch_target_calc;

    reg [31:0] pc;
    reg [31:0] imm32;
    reg [31:0] valA;
    reg [31:0] valB;
    reg [31:0] mepc;
    reg [6:0]  opcode;
    reg [2:0]  funct3;
    reg        branch;
    reg        jump;
    reg        is_reti;
    
    wire [31:0] target;
    wire        take_branch;

    branch_target_calc dut (
        .pc(pc),
        .imm32(imm32),
        .valA(valA),
        .valB(valB),
        .mepc(mepc),
        .opcode(opcode),
        .funct3(funct3),
        .branch(branch),
        .jump(jump),
        .is_reti(is_reti),
        .target(target),
        .take_branch(take_branch)
    );

    initial begin
        $display("--- RISC-V Branch Target Calculator Test ---");
        
        pc = 32'h00001004;
        imm32 = 0; valA = 0; valB = 0; mepc = 0;
        opcode = 0; funct3 = 0; branch = 0; jump = 0; is_reti = 0;
        
        // Test 1: BEQ (eq)
        #1;
        opcode = `OPC_BRANCH; funct3 = `F3_BEQ; branch = 1;
        valA = 32'd50; valB = 32'd50; imm32 = 32'd16;
        #1;
        if (take_branch !== 1 || target !== 32'h00001010) $display("FAIL: BEQ eq");

        // Test 2: JALR
        #1;
        branch = 0; jump = 1; opcode = `OPC_JALR; funct3 = `F3_JALR;
        valA = 32'h00002001; imm32 = 32'd100;
        #1;
        if (take_branch !== 1 || target !== 32'h00002064) $display("FAIL: JALR");

        // Test 3: RETI
        #1;
        is_reti = 1; mepc = 32'h12345678;
        #1;
        if (take_branch !== 1 || target !== 32'h12345678) $display("FAIL: RETI");

        $display("SUCCESS: Branch Target Calc Test completed.");
        $finish;
    end

endmodule
