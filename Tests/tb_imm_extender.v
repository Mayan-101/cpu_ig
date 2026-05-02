`timescale 1ns / 1ps

module tb_imm_extender;

    reg [25:0] instr_bits;
    reg [1:0] ext_mode;
    wire [31:0] imm32;

    imm_extender dut (
        .instr_bits(instr_bits),
        .ext_mode(ext_mode),
        .imm32(imm32)
    );

    initial begin
        $display("--- M9.3: Immediate Extender Test ---");
        
        // Test 1: Sign-extend 0x1FFF (positive in 14 bits)
        instr_bits = 26'h0001FFF; 
        ext_mode = 2'b00; // MODE_SIGN
        #1;
        $display("Sign-extend 0x1FFF = %h (Expected: 00001FFF)", imm32);
        if (imm32 !== 32'h00001FFF) $display("FAIL: Sign-extend positive");
        
        // Test 2: Sign-extend 0x2000 (negative in 14 bits)
        instr_bits = 26'h0002000;
        ext_mode = 2'b00; // MODE_SIGN
        #1;
        $display("Sign-extend 0x2000 = %h (Expected: FFFFE000)", imm32);
        if (imm32 !== 32'hFFFFE000) $display("FAIL: Sign-extend negative");
        
        // Test 3: Zero-extend 0x2000
        instr_bits = 26'h0002000;
        ext_mode = 2'b01; // MODE_ZERO
        #1;
        $display("Zero-extend 0x2000 = %h (Expected: 00002000)", imm32);
        if (imm32 !== 32'h00002000) $display("FAIL: Zero-extend");
        
        // Test 4: Jump target shift
        instr_bits = 26'h0123456;
        ext_mode = 2'b10; // MODE_JUMP
        #1;
        $display("Jump 26b 0x0123456 = %h (Expected: 0048D158)", imm32);
        if (imm32 !== 32'h0048D158) $display("FAIL: Jump target shift");
        
        // Test 5: LUI extension
        instr_bits = 26'h00ABCDE; // [19:0] is 0xABCDE
        ext_mode = 2'b11; // MODE_LUI
        #1;
        $display("LUI 20b 0xABCDE = %h (Expected: ABCDE000)", imm32);
        if (imm32 !== 32'hABCDE000) $display("FAIL: LUI extend");

        $display("Test finished.");
        $finish;
    end

endmodule
