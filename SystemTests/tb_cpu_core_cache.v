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
        // --- TEST PROGRAM: Cache Integration ---
        // 0x00: ADDI R1, R0, 0x123  ; R1 = 0x123
        // 0x04: LUI  R2, 0x20000    ; R2 = 0x20000000 (RAM Base)
        // 0x08: SW   R1, 0(R2)      ; Store 0x123
        // 0x0C: LW   R3, 0(R2)      ; Load (Compulsory Miss)
        // 0x10: LW   R5, 0(R2)      ; Load (Cache Hit)
        // 0x14: ADDI R1, R0, 0x456  ; R1 = 0x456
        // 0x18: SW   R1, 16(R2)     ; Store to different line (0x2000_0010)
        // 0x1C: LW   R6, 16(R2)     ; Load back
        // 0x20: HLT
        
        uut.itcm_inst.mem[0] = 32'h40100123;
        uut.itcm_inst.mem[1] = 32'h68210000;
        uut.itcm_inst.mem[2] = 32'h84108000;
        uut.itcm_inst.mem[3] = 32'h80308000;
        uut.itcm_inst.mem[4] = 32'h80508000;
        uut.itcm_inst.mem[5] = 32'h40100456;
        uut.itcm_inst.mem[6] = 32'h84108010;
        uut.itcm_inst.mem[7] = 32'h80608010;
        uut.itcm_inst.mem[8] = 32'hFC000000;

        $display(".3 — CPU + Cache Integration Test");
        $monitor("Time=%0t | PC=%h | Instr=%h | R3=%h | R5=%h | R6=%h | Stall=%b", 
                 $time, uut.cpu.pc, uut.cpu.instr_in, 
                 uut.cpu.rf.gp_regs[3].reg_inst.q,
                 uut.cpu.rf.gp_regs[5].reg_inst.q,
                 uut.cpu.rf.gp_regs[6].reg_inst.q,
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
        $display("R3 (0x1000_0000 load):     %h", uut.cpu.rf.gp_regs[3].reg_inst.q);
        $display("R5 (0x1000_0000 re-load):  %h", uut.cpu.rf.gp_regs[5].reg_inst.q);
        $display("R6 (0x1000_0010 load):     %h", uut.cpu.rf.gp_regs[6].reg_inst.q);
        
        if (uut.cpu.rf.gp_regs[3].reg_inst.q == 32'h00000123 && 
            uut.cpu.rf.gp_regs[5].reg_inst.q == 32'h00000123 &&
            uut.cpu.rf.gp_regs[6].reg_inst.q == 32'h00000456)
            $display("PASS: Cache edge cases verified.");
        else
            $display("FAIL: Cache data mismatch.");
            
        $finish;
    end
endmodule
