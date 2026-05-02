`timescale 1ns / 1ps

module tb_system_array_add;
    reg clk;
    reg rst;
    wire [31:0] io_data;
    wire [15:0] io_addr;
    wire io_we;
    wire stall_cpu;
    wire halt_cpu_sig;

    // Use the system with cache for a total system test
    system_cache_top uut (
        .clk(clk),
        .rst(rst),
        .io_data_out(io_data),
        .io_addr_out(io_addr),
        .io_we_out(io_we),
        .stall_cpu(stall_cpu),
        .halt_cpu(halt_cpu_sig)
    );

    always #5 clk = ~clk;

    integer i;
    initial begin
        $display("============================================================");
        $display("  SYSTEM TEST: Array Addition (5 elements)");
        $display("  Goal: Add [1,2,3,4,5] and [10,20,30,40,50]");
        $display("============================================================");
        
        clk = 0;
        rst = 1;
        #20 rst = 0;

        // Wait for HLT or timeout
        fork : timeout_watch
            begin
                #500000;
                $display("\nTIMEOUT: HLT not reached.");
                disable timeout_watch;
            end
            begin
                // Wait for the CPU to signal a committed HALT instruction
                wait(halt_cpu_sig == 1'b1); 
                #100;
                $display("\nHLT instruction reached.");
                disable timeout_watch;
            end
        join

        $display("\nVerification of Array C (Results) in RAM:");
        // Array C starts at 0x2000_0028. Offset in RAM is 0x28.
        // Word address in ram_async is offset >> 2 = 0xA.
        
        for (i = 0; i < 5; i = i + 1) begin
            $display("C[%0d] (at RAM addr %h): %d (Expected: %0d)", 
                     i, 10 + i, uut.main_ram.mem[10 + i], (i+1) + (i+1)*10);
        end

        if (uut.main_ram.mem[10] == 11 && uut.main_ram.mem[14] == 55)
            $display("\nPASS: Array addition successful!");
        else
            $display("\nFAIL: Verification mismatch.");

        $finish;
    end

    // Monitor for debug
    /*
    initial begin
        $monitor("Time=%0t | PC=%h | Instr=%h | R7(sum)=%d | Stall=%b", 
                 $time, uut.cpu.pc, uut.cpu.instr_in, uut.cpu.rf.gp_regs[7].reg_inst.q, stall_cpu);
    end
    */

endmodule
