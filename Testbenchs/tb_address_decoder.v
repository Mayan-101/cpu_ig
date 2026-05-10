`timescale 1ns / 1ps

module tb_address_decoder();

    reg [31:0] addr;
    reg we;
    reg re;
    reg [31:0] wr_data;
    
    wire itcm_sel, dtcm_sel, ram_sel, io_sel, sys_ctrl_sel;
    wire [11:0] itcm_addr;
    wire [10:0] dtcm_addr;
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
        $display("--- Address Decoder Test (16KB ITCM, 8KB DTCM) ---");
        // Test 1: ITCM Address 0
        addr = 32'h0000_0000;
        we = 0; re = 1; wr_data = 32'h0;
        #5;
        if (!itcm_sel || itcm_addr !== 12'd0)
            $display("FAIL: Test 1 (ITCM addr 0) itcm_sel=%b, itcm_addr=%h", itcm_sel, itcm_addr);
        else
            $display("PASS: Test 1 (ITCM addr 0 -> itcm_sel=1)");

        // Test 2: ITCM Max Address (0x0000_3FFF)
        addr = 32'h0000_3FFC; // Word aligned
        #5;
        if (!itcm_sel || itcm_addr !== 12'hFFF)
            $display("FAIL: Test 2 (ITCM max addr) itcm_addr=%h", itcm_addr);
        else
            $display("PASS: Test 2 (ITCM max addr)");

        // Test 2b: ITCM Out of Range (0x0000_4000)
        addr = 32'h0000_4000;
        #5;
        if (itcm_sel) $display("FAIL: Test 2b (ITCM OOR)");
        else $display("PASS: Test 2b (ITCM OOR)");

        // Test 3: DTCM Address Base (0x0001_0000)
        addr = 32'h0001_0000;
        we = 1;
        #5;
        if (!dtcm_sel || dtcm_addr !== 11'd0 || dtcm_we !== 1'b1)
            $display("FAIL: Test 3 (DTCM addr 0001_0000) dtcm_sel=%b, dtcm_addr=%h", dtcm_sel, dtcm_addr);
        else
            $display("PASS: Test 3 (DTCM addr 0001_0000)");

        // Test 3b: DTCM Max Address (0x0001_1FFF)
        addr = 32'h0001_1FFC;
        #5;
        if (!dtcm_sel || dtcm_addr !== 11'h7FF)
            $display("FAIL: Test 3b (DTCM max addr) dtcm_addr=%h", dtcm_addr);
        else
            $display("PASS: Test 3b (DTCM max addr)");

        // Test 4: RAM Address Base (0x1000_0000)
        addr = 32'h1000_0000;
        we = 1;
        #5;
        if (!ram_sel || ram_addr !== 22'd0 || ram_we !== 1'b1)
            $display("FAIL: Test 4 (RAM addr 1000_0000)");
        else
            $display("PASS: Test 4 (RAM addr 1000_0000)");

        #10;
        $display("All Address Decoder tests completed.");
        $finish;
    end

endmodule
