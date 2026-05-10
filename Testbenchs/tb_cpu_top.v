`timescale 1ns / 1ps

module tb_cpu_top();

    reg clk;
    reg rst;
    
    wire [31:0] pc_bus;
    reg [31:0] instr_bus;
    wire icache_ready = 1'b1;
    
    wire [31:0] dbus_addr;
    wire [31:0] dbus_wdata;
    wire dbus_we;
    wire dbus_re;
    reg [31:0] dbus_rdata;
    wire dcache_ready = 1'b1;
    
    wire [31:0] dbus_io_rdata = 32'd0;

    wire halt_cpu;
    cpu_top uut (
        .clk(clk), .rst(rst),
        .ibus_addr(pc_bus), .ibus_rdata(instr_bus), .ibus_ready(icache_ready),
        .dbus_addr(dbus_addr), .dbus_wdata(dbus_wdata), .dbus_we(dbus_we), .dbus_re(dbus_re),
        .dbus_rdata(dbus_rdata), .dbus_ready(dcache_ready),
        .dbus_io_rdata(dbus_io_rdata),
        .irq(1'b0),
        .halt_cpu(halt_cpu)
    );



    // Mock Instruction Memory (Word Indexed)
    reg [31:0] imem [0:255];
    always @(*) begin
        instr_bus = imem[pc_bus[9:2]];
    end

    // Mock Data Memory (Word Indexed)
    reg [31:0] dmem [0:255];
    always @(*) begin
        dbus_rdata = dmem[dbus_addr[9:2]];
    end
    always @(posedge clk) begin
        if (dbus_we) dmem[dbus_addr[9:2]] <= dbus_wdata;
    end


    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    integer i;
    initial begin
        // Initialize Memory
        for (i=0; i<256; i=i+1) begin
            imem[i] = 32'h00000000; 
            dmem[i] = 32'h00000000;
        end

        $display("Loading Bubble Sort Program...");
        $readmemh("Scripts/bubble_sort.mem", imem);
        
        // Initialize data to sort
        dmem[10] = 32'd5;
        dmem[11] = 32'd2;
        dmem[12] = 32'd9;
        dmem[13] = 32'd1;
        dmem[14] = 32'd7;

        rst = 1;
        #20 rst = 0;

        $display("Starting Bubble Sort Execution...");
        
        // Run for a long time
        #50000;

        $display("Bubble Sort Result (Memory 10-14):");
        for (i=10; i<=14; i=i+1) begin
            $display("MEM[%0d] = %d", i, dmem[i]);
        end

        $finish;
    end

endmodule
