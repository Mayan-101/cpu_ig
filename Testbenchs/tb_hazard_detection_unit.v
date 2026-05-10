`timescale 1ns / 1ps

module tb_hazard_detection_unit();

    reg [4:0] id_ex_rd_addr;
    reg       id_ex_mem_read;
    reg [4:0] if_id_rs1_addr;
    reg [4:0] if_id_rs2_addr;
    
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

        // Test 1: LW x1, 0(x2) followed by ADD x3, x1, x4
        // LW is in EX, ADD is in ID
        id_ex_mem_read = 1;
        id_ex_rd_addr = 5'd1;  // LW writes to x1
        if_id_rs1_addr = 5'd1; // ADD reads from x1
        if_id_rs2_addr = 5'd4; // ADD reads from x4
        #10;
        if (stall === 1'b1 && nop_inject === 1'b1)
            $display("PASS: Test 1 (Load-Use Hazard on rs1) - stall=1, nop_inject=1");
        else
            $display("FAIL: Test 1 (Load-Use Hazard on rs1) - stall=%b, nop_inject=%b", stall, nop_inject);

        // Test 2: LW x1, 0(x2) followed by ADD x3, x5, x1
        // Hazard on rs2
        if_id_rs1_addr = 5'd5; // ADD reads from x5
        if_id_rs2_addr = 5'd1; // ADD reads from x1
        #10;
        if (stall === 1'b1 && nop_inject === 1'b1)
            $display("PASS: Test 2 (Load-Use Hazard on rs2) - stall=1, nop_inject=1");
        else
            $display("FAIL: Test 2 (Load-Use Hazard on rs2) - stall=%b, nop_inject=%b", stall, nop_inject);

        // Test 3: LW x1, 0(x2) followed by ADD x3, x5, x4
        // No dependency
        if_id_rs1_addr = 5'd5;
        if_id_rs2_addr = 5'd4;
        #10;
        if (stall === 0 && nop_inject === 0)
            $display("PASS: Test 3 (No Hazard) - stall=0, nop_inject=0");
        else
            $display("FAIL: Test 3 (No Hazard) - stall=%b, nop_inject=%b", stall, nop_inject);

        // Test 4: ADD x1, x2, x3 followed by ADD x4, x1, x5
        // Not a Load in EX, so no stall
        id_ex_mem_read = 0;
        id_ex_rd_addr = 5'd1;
        if_id_rs1_addr = 5'd1;
        if_id_rs2_addr = 5'd5;
        #10;
        if (stall === 0 && nop_inject === 0)
            $display("PASS: Test 4 (Dependency but not Load) - stall=0, nop_inject=0");
        else
            $display("FAIL: Test 4 (Dependency but not Load) - stall=%b, nop_inject=%b", stall, nop_inject);

        // Test 5: LW x0 followed by ADD x1, x0, x2
        // Dependency on x0 (should NOT stall)
        id_ex_mem_read = 1;
        id_ex_rd_addr = 5'd0;
        if_id_rs1_addr = 5'd0;
        if_id_rs2_addr = 5'd2;
        #10;
        if (stall === 1'b0 && nop_inject === 1'b0)
            $display("PASS: Test 5 (No Load-Use on x0) - stall=0, nop_inject=0");
        else
            $display("FAIL: Test 5 (No Load-Use on x0) - stall=%b, nop_inject=%b", stall, nop_inject);

        $display("Hazard Detection Unit Test completed.");
        $finish;
    end

endmodule
