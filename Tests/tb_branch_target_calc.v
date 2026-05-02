`timescale 1ns / 1ps

module tb_branch_target_calc;

    reg [31:0] pc;
    reg [31:0] imm32;
    reg [31:0] valA;
    reg [31:0] valB;
    reg [5:0]  opcode;
    reg        branch;
    reg        jump;
    
    wire [31:0] target;
    wire        take_branch;

    branch_target_calc dut (
        .pc(pc),
        .imm32(imm32),
        .valA(valA),
        .valB(valB),
        .opcode(opcode),
        .branch(branch),
        .jump(jump),
        .target(target),
        .take_branch(take_branch)
    );

    initial begin
        $display("--- M9.7: Branch Target Calculator Test ---");
        
        pc = 32'h00001000;
        imm32 = 0;
        valA = 0;
        valB = 0;
        opcode = 0;
        branch = 0;
        jump = 0;
        
        // Test 1: BEQ with rs1==rs2
        #1;
        opcode = 6'h30; // BEQ
        branch = 1;
        valA = 32'd50;
        valB = 32'd50;
        imm32 = 32'd4; // 4 instructions = +16 bytes
        #1;
        $display("BEQ (eq): take=%b (Expected 1), target=%h (Expected 00001010)", take_branch, target);
        if (take_branch !== 1 || target !== 32'h00001010) $display("FAIL: BEQ eq");

        // Test 2: BEQ with rs1!=rs2
        #1;
        valB = 32'd60;
        #1;
        $display("BEQ (neq): take=%b (Expected 0)", take_branch);
        if (take_branch !== 0) $display("FAIL: BEQ neq");

        // Test 3: BNE with rs1!=rs2
        #1;
        opcode = 6'h31; // BNE
        #1;
        $display("BNE (neq): take=%b (Expected 1)", take_branch);
        if (take_branch !== 1) $display("FAIL: BNE neq");

        // Test 4: JALR -> take=1, target = valA + imm32
        #1;
        branch = 0;
        jump = 1;
        opcode = 6'h39; // JALR
        valA = 32'h00002000;
        imm32 = 32'd100;
        #1;
        $display("JALR: take=%b (Expected 1), target=%h (Expected 00002064)", take_branch, target);
        if (take_branch !== 1 || target !== 32'h00002064) $display("FAIL: JALR");

        // Test 5: JAL -> take=1, target = {PC[31:28], imm[27:0]}
        #1;
        opcode = 6'h38; // JAL
        pc = 32'h80000000;
        imm32 = 32'h00ABCD00; // already shifted by ext
        #1;
        $display("JAL: take=%b (Expected 1), target=%h (Expected 80ABCD00)", take_branch, target);
        if (take_branch !== 1 || target !== 32'h80ABCD00) $display("FAIL: JAL");

        $display("Test finished.");
        $finish;
    end

endmodule
