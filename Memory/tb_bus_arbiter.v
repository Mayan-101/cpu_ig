`timescale 1ns / 1ps

module tb_bus_arbiter();

    reg if_req;
    reg [31:0] if_addr;
    
    reg mem_req;
    reg [31:0] mem_addr;
    reg mem_we;
    reg [31:0] mem_data;
    
    wire [31:0] bus_addr;
    wire bus_we;
    wire [31:0] bus_wr_data;
    wire if_stall;
    wire grant;

    bus_arbiter uut (
        .if_req(if_req),
        .if_addr(if_addr),
        .mem_req(mem_req),
        .mem_addr(mem_addr),
        .mem_we(mem_we),
        .mem_data(mem_data),
        .bus_addr(bus_addr),
        .bus_we(bus_we),
        .bus_wr_data(bus_wr_data),
        .if_stall(if_stall),
        .grant(grant)
    );

    initial begin
        // Initialize
        if_req = 0; if_addr = 0;
        mem_req = 0; mem_addr = 0; mem_we = 0; mem_data = 0;
        #10;

        // Test 1: IF Only (No contention)
        if_req = 1; if_addr = 32'h0000_0004;
        mem_req = 0;
        #5;
        if (grant !== 1'b0 || if_stall !== 1'b0 || bus_addr !== 32'h0000_0004 || bus_we !== 1'b0)
            $display("FAIL: Test 1 (IF Only)");
        else
            $display("PASS: Test 1 (No contention -> IF granted)");

        // Test 2: MEM Only
        if_req = 0;
        mem_req = 1; mem_addr = 32'h0000_1004; mem_we = 1; mem_data = 32'hDEADBEEF;
        #5;
        if (grant !== 1'b1 || if_stall !== 1'b0 || bus_addr !== 32'h0000_1004 || bus_we !== 1'b1 || bus_wr_data !== 32'hDEADBEEF)
            $display("FAIL: Test 2 (MEM Only)");
        else
            $display("PASS: Test 2 (MEM Only -> MEM granted)");

        // Test 3: Simultaneous Request (Contention)
        if_req = 1; if_addr = 32'h0000_0008; // Next instruction fetch
        mem_req = 1; mem_addr = 32'h0000_1008; mem_we = 0; mem_data = 32'h0; // Concurrent load
        #5;
        if (grant !== 1'b1 || if_stall !== 1'b1 || bus_addr !== 32'h0000_1008 || bus_we !== 1'b0)
            $display("FAIL: Test 3 (Simultaneous Request)");
        else
            $display("PASS: Test 3 (Simultaneous request -> MEM granted, if_stall=1)");

        // Test 4: Next cycle, MEM request goes away
        mem_req = 0; // MEM finishes
        #5;
        // if_req is still 1 from previous cycle
        if (grant !== 1'b0 || if_stall !== 1'b0 || bus_addr !== 32'h0000_0008)
            $display("FAIL: Test 4 (MEM request dropped)");
        else
            $display("PASS: Test 4 (Next cycle, no MEM request -> IF granted, stall drops)");

        #10;
        $display("All Bus Arbiter tests completed.");
        $finish;
    end

endmodule
