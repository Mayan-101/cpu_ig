`timescale 1ns / 1ps

module tb_address_decoder();

    reg [31:0] addr;
    reg we;
    reg re;
    reg [31:0] wr_data;
    
    wire rom_sel;
    wire ram_sel;
    wire io_sel;
    wire [9:0] rom_addr;
    wire [4:0] ram_addr;
    wire [15:0] io_addr;
    wire rom_we;
    wire ram_we;
    wire io_we;

    address_decoder uut (
        .addr(addr),
        .we(we),
        .re(re),
        .wr_data(wr_data),
        .rom_sel(rom_sel),
        .ram_sel(ram_sel),
        .io_sel(io_sel),
        .rom_addr(rom_addr),
        .ram_addr(ram_addr),
        .io_addr(io_addr),
        .rom_we(rom_we),
        .ram_we(ram_we),
        .io_we(io_we)
    );

    initial begin
        // Test 1: ROM Address 0
        addr = 32'h0000_0000;
        we = 0; re = 1; wr_data = 32'h0;
        #5;
        if (!rom_sel || ram_sel || io_sel || rom_addr !== 10'd0)
            $display("FAIL: Test 1 (ROM addr 0)");
        else
            $display("PASS: Test 1 (ROM addr 0 -> rom_sel=1)");

        // Test 2: ROM Max Address (0x0FFF)
        addr = 32'h0000_0FFC; // Word aligned
        #5;
        if (!rom_sel || ram_sel || io_sel || rom_addr !== 10'h3FF)
            $display("FAIL: Test 2 (ROM addr 0FFC) rom_addr=%h", rom_addr);
        else
            $display("PASS: Test 2 (ROM addr 0FFC -> rom_sel=1, max addr)");

        // Test 3: ROM Write Attempt
        addr = 32'h0000_0100;
        we = 1;
        #5;
        if (rom_we !== 1'b0)
            $display("FAIL: Test 3 (ROM Write Attempt)");
        else
            $display("PASS: Test 3 (ROM Write Attempt -> rom_we=0)");

        // Test 4: RAM Address Base (0x1000)
        addr = 32'h0000_1000;
        we = 1;
        #5;
        if (rom_sel || !ram_sel || io_sel || ram_addr !== 5'd0 || ram_we !== 1'b1)
            $display("FAIL: Test 4 (RAM addr 1000)");
        else
            $display("PASS: Test 4 (RAM addr 1000 -> ram_sel=1, ram_we=1)");

        // Test 5: RAM Max Address (0x107C)
        addr = 32'h0000_107C;
        #5;
        if (rom_sel || !ram_sel || io_sel || ram_addr !== 5'h1F)
            $display("FAIL: Test 5 (RAM addr 107C)");
        else
            $display("PASS: Test 5 (RAM addr 107C -> ram_sel=1, max addr)");

        // Test 6: I/O Address (0x1080)
        addr = 32'h0000_1080;
        we = 1;
        #5;
        if (rom_sel || ram_sel || !io_sel || io_we !== 1'b1)
            $display("FAIL: Test 6 (I/O addr 1080)");
        else
            $display("PASS: Test 6 (I/O addr 1080 -> io_sel=1, io_we=1)");

        // Test 7: Deep I/O Address
        addr = 32'h1234_5678;
        #5;
        if (rom_sel || ram_sel || !io_sel || io_addr !== 16'h5678)
            $display("FAIL: Test 7 (I/O deep addr)");
        else
            $display("PASS: Test 7 (I/O deep addr -> io_sel=1, io_addr=%h)", io_addr);

        #10;
        $display("All Address Decoder tests completed.");
        $finish;
    end

endmodule
