`timescale 1ns / 1ps

module tb_program_tester;
    reg clk;
    reg rst;
    wire halt_cpu_sig;

    system_cache_top uut (
        .clk(clk),
        .rst(rst),
        .halt_cpu(halt_cpu_sig)
    );

    always #5 clk = ~clk;

    integer i;
    initial begin
        $display("============================================================");
        $display("  PROGRAM TESTER: Executing bubble_sort.mem");
        $display("============================================================");
        
        $readmemh("Scripts/bubble_sort.mem", uut.main_rom.mem);
        
        // Initialize RAM with unsorted data for bubble sort
        uut.main_ram.mem[0] = 32'h0000000A;
        uut.main_ram.mem[1] = 32'h00000001;
        uut.main_ram.mem[2] = 32'h00000009;
        uut.main_ram.mem[3] = 32'h00000002;
        uut.main_ram.mem[4] = 32'h00000008;
        uut.main_ram.mem[5] = 32'h00000003;
        uut.main_ram.mem[6] = 32'h00000007;
        uut.main_ram.mem[7] = 32'h00000004;
        uut.main_ram.mem[8] = 32'h00000006;
        uut.main_ram.mem[9] = 32'h00000005;

        clk = 0;
        rst = 1;
        #20 rst = 0;

        // Wait for HLT or timeout
        fork : timeout_watch
            begin
                #2000000; // Longer timeout for matrix multiplication
                $display("\nTIMEOUT: HLT not reached.");
                disable timeout_watch;
            end
            begin
                wait(halt_cpu_sig == 1'b1); 
                #100;
                $display("\nHLT instruction reached.");
                disable timeout_watch;
            end
        join

        $display("\nRAM Result Dump (Offset 0x0 to 0x3F):");
        for (i = 0; i < 64; i = i + 1) begin
            if (uut.main_ram.mem[i] !== 32'hx)
                $display("RAM[%h]: %h", i, uut.main_ram.mem[i]);
        end

        $finish;
    end
endmodule
