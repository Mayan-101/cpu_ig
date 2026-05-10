`timescale 1ns / 1ps

module tb_forwarding_unit();

    reg [4:0] ex_mem_rd_addr;
    reg       ex_mem_reg_write;
    reg [4:0] mem_wb_rd_addr;
    reg       mem_wb_reg_write;
    reg [4:0] id_ex_rs1_addr;
    reg [4:0] id_ex_rs2_addr;
    
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
        // ADD x1, x2, x3 (EX/MEM)
        // SUB x4, x1, x5 (ID/EX)
        ex_mem_reg_write = 1; ex_mem_rd_addr = 5'd1;
        id_ex_rs1_addr = 5'd1; id_ex_rs2_addr = 5'd5;
        #10;
        if (forwardA === 2'b10 && forwardB === 2'b00)
            $display("PASS: Test 1 (EX-EX rs1) forwardA=10, forwardB=00");
        else
            $display("FAIL: Test 1 (EX-EX rs1) forwardA=%b, forwardB=%b", forwardA, forwardB);

        // Test 2: MEM-EX dependency on rs2
        // ADD x1, x2, x3 (MEM/WB)
        // SUB x4, x5, x1 (ID/EX)
        ex_mem_reg_write = 0; ex_mem_rd_addr = 5'd0;
        mem_wb_reg_write = 1; mem_wb_rd_addr = 5'd1;
        id_ex_rs1_addr = 5'd5; id_ex_rs2_addr = 5'd1;
        #10;
        if (forwardA === 2'b00 && forwardB === 2'b01)
            $display("PASS: Test 2 (MEM-EX rs2) forwardA=00, forwardB=01");
        else
            $display("FAIL: Test 2 (MEM-EX rs2) forwardA=%b, forwardB=%b", forwardA, forwardB);

        // Test 3: Double dependency (rs1 from EX, rs2 from MEM)
        ex_mem_reg_write = 1; ex_mem_rd_addr = 5'd2;
        mem_wb_reg_write = 1; mem_wb_rd_addr = 5'd3;
        id_ex_rs1_addr = 5'd2; id_ex_rs2_addr = 5'd3;
        #10;
        if (forwardA === 2'b10 && forwardB === 2'b01)
            $display("PASS: Test 3 (Double dependency) forwardA=10, forwardB=01");
        else
            $display("FAIL: Test 3 (Double dependency) forwardA=%b, forwardB=%b", forwardA, forwardB);

        // Test 4: Priority Test (EX stage should win for same register)
        ex_mem_reg_write = 1; ex_mem_rd_addr = 5'd1;
        mem_wb_reg_write = 1; mem_wb_rd_addr = 5'd1;
        id_ex_rs1_addr = 5'd1;
        #10;
        if (forwardA === 2'b10)
            $display("PASS: Test 4 (Priority EX over MEM) forwardA=10");
        else
            $display("FAIL: Test 4 (Priority EX over MEM) forwardA=%b", forwardA);

        $display("Forwarding Unit Test completed.");
        $finish;
    end

endmodule
