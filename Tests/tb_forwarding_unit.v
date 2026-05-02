`timescale 1ns / 1ps

module tb_forwarding_unit();

    reg [5:0] ex_mem_rd_addr;
    reg       ex_mem_reg_write;
    reg [5:0] mem_wb_rd_addr;
    reg       mem_wb_reg_write;
    reg [5:0] id_ex_rs1_addr;
    reg [5:0] id_ex_rs2_addr;
    
    wire [1:0] forwardA;
    wire [1:0] forwardB;

    forwarding_unit uut (
        .ex_mem_rd_addr(ex_mem_rd_addr),
        .ex_mem_reg_write(ex_mem_reg_write),
        .mem_wb_rd_addr(mem_wb_rd_addr),
        .mem_wb_reg_write(mem_wb_reg_write),
        .id_ex_rs1_addr(id_ex_rs1_addr),
        .id_ex_rs2_addr(id_ex_rs2_addr),
        .forwardA(forwardA),
        .forwardB(forwardB)
    );

    initial begin
        // Initialize
        ex_mem_rd_addr = 0; ex_mem_reg_write = 0;
        mem_wb_rd_addr = 0; mem_wb_reg_write = 0;
        id_ex_rs1_addr = 0; id_ex_rs2_addr = 0;

        $display("Starting Forwarding Unit Test...");

        // Test 1: EX-EX dependency on rs1
        // ADD R1, R2, R3 (EX/MEM)
        // SUB R4, R1, R5 (ID/EX)
        ex_mem_reg_write = 1; ex_mem_rd_addr = 6'd1;
        id_ex_rs1_addr = 6'd1; id_ex_rs2_addr = 6'd5;
        #10;
        if (forwardA === 2'b10 && forwardB === 2'b00)
            $display("PASS: Test 1 (EX-EX rs1) forwardA=10, forwardB=00");
        else
            $display("FAIL: Test 1 (EX-EX rs1) forwardA=%b, forwardB=%b", forwardA, forwardB);

        // Test 2: MEM-EX dependency on rs2
        // ADD R1, R2, R3 (MEM/WB)
        // SUB R4, R5, R1 (ID/EX)
        ex_mem_reg_write = 0; ex_mem_rd_addr = 6'd0;
        mem_wb_reg_write = 1; mem_wb_rd_addr = 6'd1;
        id_ex_rs1_addr = 6'd5; id_ex_rs2_addr = 6'd1;
        #10;
        if (forwardA === 2'b00 && forwardB === 2'b01)
            $display("PASS: Test 2 (MEM-EX rs2) forwardA=00, forwardB=01");
        else
            $display("FAIL: Test 2 (MEM-EX rs2) forwardA=%b, forwardB=%b", forwardA, forwardB);

        // Test 3: Double dependency (rs1 from EX, rs2 from MEM)
        ex_mem_reg_write = 1; ex_mem_rd_addr = 6'd2;
        mem_wb_reg_write = 1; mem_wb_rd_addr = 6'd3;
        id_ex_rs1_addr = 6'd2; id_ex_rs2_addr = 6'd3;
        #10;
        if (forwardA === 2'b10 && forwardB === 2'b01)
            $display("PASS: Test 3 (Double dependency) forwardA=10, forwardB=01");
        else
            $display("FAIL: Test 3 (Double dependency) forwardA=%b, forwardB=%b", forwardA, forwardB);

        // Test 4: Priority Test (EX stage should win for same register)
        // ADD R1, R2, R3 (MEM/WB)
        // ADD R1, R4, R5 (EX/MEM)
        // SUB R6, R1, R7 (ID/EX)
        ex_mem_reg_write = 1; ex_mem_rd_addr = 6'd1;
        mem_wb_reg_write = 1; mem_wb_rd_addr = 6'd1;
        id_ex_rs1_addr = 6'd1;
        #10;
        if (forwardA === 2'b10)
            $display("PASS: Test 4 (Priority EX over MEM) forwardA=10");
        else
            $display("FAIL: Test 4 (Priority EX over MEM) forwardA=%b", forwardA);

        // Test 5: No dependency
        ex_mem_reg_write = 1; ex_mem_rd_addr = 6'd10;
        mem_wb_reg_write = 1; mem_wb_rd_addr = 6'd11;
        id_ex_rs1_addr = 6'd12; id_ex_rs2_addr = 6'd13;
        #10;
        if (forwardA === 2'b00 && forwardB === 2'b00)
            $display("PASS: Test 5 (No dependency) forwardA=00, forwardB=00");
        else
            $display("FAIL: Test 5 (No dependency) forwardA=%b, forwardB=%b", forwardA, forwardB);

        $display("Forwarding Unit Test completed.");
        $finish;
    end

endmodule
