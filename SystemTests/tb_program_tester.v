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
        $display("  PROGRAM TESTER: Executing current ROM content");
        $display("============================================================");
        
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
