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
                 uut.cpu.rf.gp_regs[1].reg_inst.q,
                 uut.cpu.rf.gp_regs[2].reg_inst.q,
                 uut.cpu.rf.gp_regs[3].reg_inst.q,
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
        $display("R3 (0x2000_0000 load):     %h", uut.cpu.rf.gp_regs[3].reg_inst.q);
        $display("R5 (0x2000_0000 re-load):  %h", uut.cpu.rf.gp_regs[5].reg_inst.q);
        $display("R6 (0x2000_0010 load):     %h", uut.cpu.rf.gp_regs[6].reg_inst.q);
        
        if (uut.cpu.rf.gp_regs[3].reg_inst.q == 32'h00000123 && 
            uut.cpu.rf.gp_regs[5].reg_inst.q == 32'h00000123 &&
            uut.cpu.rf.gp_regs[6].reg_inst.q == 32'h00000456)
            $display("PASS: Cache edge cases verified.");
        else
            $display("FAIL: Cache data mismatch.");
            
        $finish;
    end
endmodule
