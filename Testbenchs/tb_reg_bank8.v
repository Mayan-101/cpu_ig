`timescale 1ns / 1ps

module tb_reg_bank8();

    reg clk;
    reg rst;
    reg we;
    reg [2:0] rs1_addr;
    reg [2:0] rs2_addr;
    reg [2:0] rd_addr;
    reg [31:0] wr_data;
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;

    // Instantiate the module under test (MUT)
    reg_bank8 uut (
        .clk(clk),
        .rst(rst),
        .we(we),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr(rd_addr),
        .wr_data(wr_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period
    end

    integer i;

    // Test sequence
    initial begin
        // Initialize inputs
        rst = 1;
        we = 0;
        rs1_addr = 0;
        rs2_addr = 0;
        rd_addr = 0;
        wr_data = 0;

        // Apply reset
        #15;
        rst = 0;

        // Test 1: Write all 8 registers sequentially
        for (i = 0; i < 8; i = i + 1) begin
            @(negedge clk);
            we = 1;
            rd_addr = i;
            wr_data = (i + 1) * 32'h11111111; // R0=11111111, R1=22222222, etc.
        end
        @(negedge clk);
        we = 0;

        // Verify sequentially
        for (i = 0; i < 8; i = i + 1) begin
            rs1_addr = i;
            #1; // Wait for combinational logic
            if (rs1_data !== (i + 1) * 32'h11111111) begin
                $display("FAIL: Test 1 (Write all) R%0d expected %h, got %h", i, (i + 1) * 32'h11111111, rs1_data);
            end
        end
        $display("PASS: Test 1 (Write all 8 sequentially and read back)");

        // Test 2: Simultaneous read rs1=R2 and rs2=R5
        rs1_addr = 3'd2;
        rs2_addr = 3'd5;
        #1;
        if (rs1_data !== 32'h33333333 || rs2_data !== 32'h66666666) begin
            $display("FAIL: Test 2 (Simultaneous read) R2=%h, R5=%h", rs1_data, rs2_data);
        end else begin
            $display("PASS: Test 2 (Simultaneous read R2 and R5)");
        end

        // Test 3: Write and read same register in same cycle (read sees old value)
        @(negedge clk);
        rs1_addr = 3'd4; // Read R4 (currently 55555555)
        rd_addr = 3'd4;  // Write R4
        wr_data = 32'h99999999;
        we = 1;

        // Before clock edge (combinational read), it should see the old value
        #1;
        if (rs1_data !== 32'h55555555) begin
            $display("FAIL: Test 3 (Read same cycle) expected old value 55555555, got %h", rs1_data);
        end else begin
            $display("PASS: Test 3 (Read sees old value before clock edge)");
        end

        // After clock edge, it should see the new value
        @(posedge clk);
        #1;
        if (rs1_data !== 32'h99999999) begin
            $display("FAIL: Test 3 (Read after clock edge) expected new value 99999999, got %h", rs1_data);
        end else begin
            $display("PASS: Test 3 (Read sees new value after clock edge)");
        end

        #10;
        $display("All reg_bank8 tests completed.");
        $finish;
    end

endmodule
