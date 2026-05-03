`timescale 1ns / 1ps

module tb_hazard_detection_unit();

    reg [5:0] id_ex_rd_addr;
    reg       id_ex_mem_read;
    reg [5:0] if_id_rs1_addr;
    reg [5:0] if_id_rs2_addr;
    
    wire      stall;
    wire      nop_inject;

    // Instantiate the module under test
    hazard_detection_unit uut (
        .id_ex_rd_addr(id_ex_rd_addr),
        .id_ex_mem_read(id_ex_mem_read),
        .if_id_rs1_addr(if_id_rs1_addr),
        .if_id_rs2_addr(if_id_rs2_addr),
        .stall(stall),
        .nop_inject(nop_inject)
    );

    initial begin
        // Initialize inputs
        id_ex_rd_addr = 0;
        id_ex_mem_read = 0;
        if_id_rs1_addr = 0;
        if_id_rs2_addr = 0;

        $display("Starting Hazard Detection Unit Test...");

        // Test 1: LW R1, 0(R2) followed by ADD R3, R1, R4
        // LW is in EX, ADD is in ID
        id_ex_mem_read = 1;
        id_ex_rd_addr = 6'd1;  // LW writes to R1
        if_id_rs1_addr = 6'd1; // ADD reads from R1
        if_id_rs2_addr = 6'd4; // ADD reads from R4
        #10;
        if (stall === 1'b1 && nop_inject === 1'b1)
            $display("PASS: Test 1 (Load-Use Hazard on rs1) - stall=1, nop_inject=1");
        else
            $display("FAIL: Test 1 (Load-Use Hazard on rs1) - stall=%b, nop_inject=%b", stall, nop_inject);

        // Test 2: LW R1, 0(R2) followed by ADD R3, R5, R1
        // Hazard on rs2
        if_id_rs1_addr = 6'd5; // ADD reads from R5
        if_id_rs2_addr = 6'd1; // ADD reads from R1
        #10;
        if (stall === 1'b1 && nop_inject === 1'b1)
            $display("PASS: Test 2 (Load-Use Hazard on rs2) - stall=1, nop_inject=1");
        else
            $display("FAIL: Test 2 (Load-Use Hazard on rs2) - stall=%b, nop_inject=%b", stall, nop_inject);

        // Test 3: LW R1, 0(R2) followed by ADD R3, R5, R4
        // No dependency
        if_id_rs1_addr = 6'd5;
        if_id_rs2_addr = 6'd4;
        #10;
        if (stall === 0 && nop_inject === 0)
            $display("PASS: Test 3 (No Hazard) - stall=0, nop_inject=0");
        else
            $display("FAIL: Test 3 (No Hazard) - stall=%b, nop_inject=%b", stall, nop_inject);

        // Test 4: ADD R1, R2, R3 followed by ADD R4, R1, R5
        // Not a Load in EX, so no stall (Forwarding should handle this, not Hazard unit)
        id_ex_mem_read = 0;
        id_ex_rd_addr = 6'd1;
        if_id_rs1_addr = 6'd1;
        if_id_rs2_addr = 6'd5;
        #10;
        if (stall === 0 && nop_inject === 0)
            $display("PASS: Test 4 (Dependency but not Load) - stall=0, nop_inject=0");
        else
            $display("FAIL: Test 4 (Dependency but not Load) - stall=%b, nop_inject=%b", stall, nop_inject);

        // Test 5: LW R1 followed by SW R1, 0(R2)
        // SW uses R1 as a source (rd in opcode format, but mapped to rs2 in id_stage)
        id_ex_mem_read = 1;
        id_ex_rd_addr = 6'd1;
        if_id_rs1_addr = 6'd2; // rs1
        if_id_rs2_addr = 6'd1; // rs2 (mapped from rd)
        #10;
        if (stall === 1'b1 && nop_inject === 1'b1)
            $display("PASS: Test 5 (Load followed by SW) - stall=1, nop_inject=1");
        else
            $display("FAIL: Test 5 (Load followed by SW) - stall=%b, nop_inject=%b", stall, nop_inject);

        // Test 6: LW R0 followed by ADD R1, R0, R2
        // Dependency on R0
        id_ex_mem_read = 1;
        id_ex_rd_addr = 6'd0;
        if_id_rs1_addr = 6'd0;
        if_id_rs2_addr = 6'd2;
        #10;
        if (stall === 1'b0 && nop_inject === 1'b0)
            $display("PASS: Test 6 (No Load-Use on R0) - stall=0, nop_inject=0");
        else
            $display("FAIL: Test 6 (No Load-Use on R0) - stall=%b, nop_inject=%b", stall, nop_inject);

        $display("Hazard Detection Unit Test completed.");
        $finish;
    end

endmodule
