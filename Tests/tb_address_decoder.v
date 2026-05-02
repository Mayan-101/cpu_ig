`timescale 1ns / 1ps

module tb_address_decoder();

    reg [31:0] addr;
    reg we;
    reg re;
    reg [31:0] wr_data;
    
    wire rom_sel;
    wire ram_sel;
    wire io_sel;
    wire sys_ctrl_sel;
    
    wire [15:0] rom_addr;
    wire [13:0] ram_addr;
    wire [11:0] io_addr;
    wire [11:0] sys_addr;
    
    wire rom_we;
    wire ram_we;
    wire io_we;
    wire sys_ctrl_we;

    address_decoder uut (
        .addr(addr), .we(we), .re(re), .wr_data(wr_data),
        .rom_sel(rom_sel), .ram_sel(ram_sel), .io_sel(io_sel), .sys_ctrl_sel(sys_ctrl_sel),
        .rom_addr(rom_addr), .ram_addr(ram_addr), .io_addr(io_addr), .sys_addr(sys_addr),
        .rom_we(rom_we), .ram_we(ram_we), .io_we(io_we), .sys_ctrl_we(sys_ctrl_we)
    );

    initial begin
        // Test 1: ROM Address 0
        addr = 32'h0000_0000;
        we = 0; re = 1; wr_data = 32'h0;
        #5;
        if (!rom_sel || rom_addr !== 16'd0)
            $display("FAIL: Test 1 (ROM addr 0)");
        else
            $display("PASS: Test 1 (ROM addr 0 -> rom_sel=1)");

        // Test 2: ROM Max Address (0x0003_FFFF)
        addr = 32'h0003_FFFC; // Word aligned
        #5;
        if (!rom_sel || rom_addr !== 16'hFFFF)
            $display("FAIL: Test 2 (ROM addr 3FFFC) rom_addr=%h", rom_addr);
        else
            $display("PASS: Test 2 (ROM addr 3FFFC -> rom_sel=1, max addr)");

        // Test 3: RAM Address Base (0x2000_0000)
        addr = 32'h2000_0000;
        we = 1;
        #5;
        if (!ram_sel || ram_addr !== 14'd0 || ram_we !== 1'b1)
            $display("FAIL: Test 3 (RAM addr 2000_0000)");
        else
            $display("PASS: Test 3 (RAM addr 2000_0000 -> ram_sel=1, ram_we=1)");

        // Test 4: Peripheral Space (0x4000_0000)
        addr = 32'h4000_0100;
        we = 1;
        #5;
        if (!io_sel || io_addr !== 12'h100 || io_we !== 1'b1)
            $display("FAIL: Test 4 (I/O addr 4000_0100)");
        else
            $display("PASS: Test 4 (I/O addr 4000_0100 -> io_sel=1, io_we=1)");

        // Test 5: System Control (0x8000_0000)
        addr = 32'h8000_0008;
        we = 1;
        #5;
        if (!sys_ctrl_sel || sys_addr !== 12'h8 || sys_ctrl_we !== 1'b1)
            $display("FAIL: Test 5 (Sys addr 8000_0008)");
        else
            $display("PASS: Test 5 (Sys addr 8000_0008 -> sys_ctrl_sel=1, sys_ctrl_we=1)");

        #10;
        $display("All Address Decoder tests completed.");
        $finish;
    end

endmodule
