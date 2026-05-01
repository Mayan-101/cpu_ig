`timescale 1ns / 1ps

module tb_cpu_core_cache;
    reg clk;
    reg rst;
    wire [31:0] io_data;
    wire [15:0] io_addr;
    wire io_we;
    wire stall_cpu;

    system_cache_top uut (
        .clk(clk),
        .rst(rst),
        .io_data_out(io_data),
        .io_addr_out(io_addr),
        .io_we_out(io_we),
        .stall_cpu(stall_cpu)
    );

    always #5 clk = ~clk;

    initial begin
        $display(".3 — CPU + Cache Integration Test");
        $monitor("Time=%0t | PC=%h | Instr=%h | R1=%h | R2=%h | R3=%h | Stall=%b", 
                 $time, uut.cpu.pc, uut.cpu.instr_in, 
                 uut.cpu.rf.banks[0].bank_inst.bank[1].r.q,
                 uut.cpu.rf.banks[0].bank_inst.bank[2].r.q,
                 uut.cpu.rf.banks[0].bank_inst.bank[3].r.q,
                 stall_cpu);
        
        clk = 0;
        rst = 1;
        #20 rst = 0;

        // Run for enough time to complete the loop (8 iterations)
        // Each loop iteration: LW (1-3 cycles if miss), SUBI (1), BNE (1)
        // Miss takes ~4 cycles. 8 iterations * 6 cycles = 48 cycles.
        // #1000 should be enough.
        #2000;
        
        $display("Final Verification:");
        $display("R2 (should be 0): %h", uut.cpu.rf.banks[0].bank_inst.bank[2].r.q);
        $display("R3 (should be loaded value): %h", uut.cpu.rf.banks[0].bank_inst.bank[3].r.q);
        
        if (uut.cpu.rf.banks[0].bank_inst.bank[2].r.q == 0)
            $display("PASS: Loop completed successfully.");
        else
            $display("FAIL: Loop did not complete correctly.");
            
        $finish;
    end
endmodule
