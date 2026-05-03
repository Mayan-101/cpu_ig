`timescale 1ns / 1ps

/**
 * Universal Testbench for Program Verification
 */

module tb_universal;
    reg clk;
    reg rst;
    wire halt_cpu_sig;

    // Instantiate System
    system_cache_top uut (
        .clk(clk),
        .rst(rst),
        .halt_cpu(halt_cpu_sig)
    );

    // Clock Generation
    always #5 clk = ~clk;

    // Simulation Control
    integer i;
    reg [1023:0] prog_file, data_file;
    integer dump_start = 0;
    integer dump_end = 127;
    integer show_float = 0;
    integer debug_mode = 0;

    initial begin
        $display("[TESTBENCH] Simulation starting...");
        // Load Program File
        if ($value$plusargs("PROG=%s", prog_file)) begin
            $readmemh(prog_file, uut.main_rom.mem);
        end
        
        // Load Data File (RAM)
        if (!$value$plusargs("DATA=%s", data_file)) begin
            data_file = "Programs/ram_init.mem";
        end
        $readmemh(data_file, uut.main_ram.mem);

        // Get Parameters
        if (!$value$plusargs("DUMP_START=%d", dump_start)) dump_start = 0;
        if (!$value$plusargs("DUMP_END=%d", dump_end))     dump_end = 127;
        if (!$value$plusargs("FLOAT=%d", show_float))      show_float = 0;
        if (!$value$plusargs("DEBUG=%d", debug_mode))      debug_mode = 0;

        clk = 0;
        rst = 1;
        #20 rst = 0;

        $display("\n[SYSTEM] Simulation started: %0s", prog_file);

        fork : main_sim
            begin
                #50000000; // 50ms timeout
                $display("\n[ERROR] TIMEOUT reached.");
                $finish;
            end
            begin
                while (halt_cpu_sig !== 1'b1) begin
                    @(posedge clk);
                end
                $display("\n[SUCCESS] HLT instruction reached at time %t", $time);
                disable main_sim;
            end
        join

        // RAM Data Dump
        $display("\n============================================================");
        $display("                DATA MEMORY (RAM) DUMP");
        $display("============================================================\n");
        
        for (i = dump_start; i <= dump_end; i = i + 1) begin
            if (uut.main_ram.mem[i] !== 32'hx && uut.main_ram.mem[i] !== 32'd0) begin
                if (show_float) begin
                    $display("RAM[0x%h]: %h", (i*4 + 32'h20000000), uut.main_ram.mem[i]);
                end else begin
                    $display("RAM[0x%h]: %d (0x%h)", (i*4 + 32'h20000000), $signed(uut.main_ram.mem[i]), uut.main_ram.mem[i]);
                end
            end
        end
        $display("\n============================================================\n");

        $finish;
    end

endmodule
