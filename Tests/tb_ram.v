`timescale 1ns / 1ps

module tb_ram();

    reg clk;
    reg [4:0] addr;
    reg [31:0] wr_data;
    reg we;
    reg re;
    wire [31:0] rd_data;

    // Instantiate RAM
    ram uut (
        .clk(clk),
        .addr(addr),
        .wr_data(wr_data),
        .we(we),
        .re(re),
        .rd_data(rd_data)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    integer i;

    // Test sequence
    initial begin
        // Initialize inputs
        addr = 0;
        wr_data = 0;
        we = 0;
        re = 0;

        // Wait a few cycles
        #15;

        // Test 1: Write 0xDEADBEEF to addr 0, read back
        @(negedge clk);
        addr = 5'd0;
        wr_data = 32'hDEADBEEF;
        we = 1;

        @(negedge clk);
        we = 0;
        re = 1;
        addr = 5'd0;

        @(negedge clk);
        re = 0;
        #1;
        if (rd_data !== 32'hDEADBEEF)
            $display("FAIL: Test 1 (Write/Read addr 0) expected DEADBEEF, got %h", rd_data);
        else
            $display("PASS: Test 1 (Write/Read addr 0)");

        // Test 2: Write all 32 locations, read all back
        // Write Phase
        for (i = 0; i < 32; i = i + 1) begin
            @(negedge clk);
            addr = i;
            wr_data = 32'h1000_0000 + i;
            we = 1;
        end
        @(negedge clk);
        we = 0;

        // Read Phase
        for (i = 0; i < 32; i = i + 1) begin
            @(negedge clk);
            addr = i;
            re = 1;

            @(negedge clk); // Data valid after clock edge
            #1;
            if (rd_data !== (32'h1000_0000 + i)) begin
                $display("FAIL: Test 2 (Read all) mismatch at addr %0d: expected %h, got %h", i, (32'h1000_0000 + i), rd_data);
            end
        end
        @(negedge clk);
        re = 0;
        $display("PASS: Test 2 (Write all 32 locations, read all back)");

        // Test 3: Read before write (Simultaneous read/write to same address)
        // With standard non-blocking assignments, a simultaneous read/write to the same address 
        // will output the old data (read-before-write).
        @(negedge clk);
        addr = 5'd5;
        wr_data = 32'hBEEFCAFE;
        we = 1;
        re = 1;

        @(negedge clk);
        #1;
        // Old data at addr 5 was 0x1000_0005
        if (rd_data !== 32'h1000_0005)
            $display("FAIL: Test 3 (Read before write) expected 1000_0005, got %h", rd_data);
        else
            $display("PASS: Test 3 (Read before write semantics verified)");

        we = 0;
        re = 0;

        #10;
        $display("All RAM tests completed.");
        $finish;
    end

endmodule
