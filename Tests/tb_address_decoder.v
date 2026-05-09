`timescale 1ns / 1ps

module tb_address_decoder();

    reg [31:0] addr;
    reg we;
    reg re;
    reg [31:0] wr_data;
    
    wire itcm_sel, dtcm_sel, ram_sel, io_sel, sys_ctrl_sel;
    wire [13:0] itcm_addr, dtcm_addr;
    wire [21:0] ram_addr;
    wire [11:0] io_addr, sys_addr;
    wire itcm_we, dtcm_we, ram_we, io_we, sys_ctrl_we;

    address_decoder uut (
        .addr(addr), .we(we), .re(re), .wr_data(wr_data),
        .itcm_sel(itcm_sel), .dtcm_sel(dtcm_sel), .ram_sel(ram_sel), .io_sel(io_sel), .sys_ctrl_sel(sys_ctrl_sel),
        .itcm_addr(itcm_addr), .dtcm_addr(dtcm_addr), .ram_addr(ram_addr), .io_addr(io_addr), .sys_addr(sys_addr),
        .itcm_we(itcm_we), .dtcm_we(dtcm_we), .ram_we(ram_we), .io_we(io_we), .sys_ctrl_we(sys_ctrl_we)
    );

    initial begin
        $display("--- Address Decoder Test (New Map) ---");
        // Test 1: ITCM Address 0
        addr = 32'h0000_0000;
        we = 0; re = 1; wr_data = 32'h0;
        #5;
        if (!itcm_sel || itcm_addr !== 14'd0)
            $display("FAIL: Test 1 (ITCM addr 0)");
        else
            $display("PASS: Test 1 (ITCM addr 0 -> itcm_sel=1)");

        // Test 2: ITCM Max Address (0x0000_FFFF)
        addr = 32'h0000_FFFC; // Word aligned
        #5;
        if (!itcm_sel || itcm_addr !== 14'h3FFF)
            $display("FAIL: Test 2 (ITCM max addr) itcm_addr=%h", itcm_addr);
        else
            $display("PASS: Test 2 (ITCM max addr)");

        // Test 3: DTCM Address Base (0x0001_0000)
        addr = 32'h0001_0000;
        we = 1;
        #5;
        if (!dtcm_sel || dtcm_addr !== 14'd0 || dtcm_we !== 1'b1)
            $display("FAIL: Test 3 (DTCM addr 0001_0000)");
        else
            $display("PASS: Test 3 (DTCM addr 0001_0000)");

        // Test 4: RAM Address Base (0x1000_0000)
        addr = 32'h1000_0000;
        we = 1;
        #5;
        if (!ram_sel || ram_addr !== 22'd0 || ram_we !== 1'b1)
            $display("FAIL: Test 4 (RAM addr 1000_0000) ram_sel=%b, ram_addr=%h", ram_sel, ram_addr);
        else
            $display("PASS: Test 4 (RAM addr 1000_0000)");

        // Test 5: Peripheral Space (0x4000_0000)
        addr = 32'h4000_0100;
        we = 1;
        #5;
        if (!io_sel || io_addr !== 12'h100 || io_we !== 1'b1)
            $display("FAIL: Test 5 (I/O addr 4000_0100)");
        else
            $display("PASS: Test 5 (I/O addr 4000_0100)");

        // Test 6: System Control (0x8000_0000)
        addr = 32'h8000_0008;
        we = 1;
        #5;
        if (!sys_ctrl_sel || sys_addr !== 12'h8 || sys_ctrl_we !== 1'b1)
            $display("FAIL: Test 6 (Sys addr 8000_0008)");
        else
            $display("PASS: Test 6 (Sys addr 8000_0008)");

        #10;
        $display("All Address Decoder tests completed.");
        $finish;
    end

endmodule
