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
        // --- RISC-V TEST PROGRAM: Cache Integration ---
        // 0x00: ADDI x1, x0, 0x123
        // 0x04: LUI  x2, 0x20000    (x2 = 0x20000000)
        // 0x08: SW   x1, 0(x2)
        // 0x0C: LW   x3, 0(x2)
        // 0x10: LW   x5, 0(x2)
        // 0x14: ADDI x1, x0, 0x456
        // 0x18: SW   x1, 16(x2)
        // 0x1C: LW   x6, 16(x2)
        // 0x20: HLT
        
        uut.itcm_inst.mem[0] = 32'h12300093;
        uut.itcm_inst.mem[1] = 32'h10000137;
        uut.itcm_inst.mem[2] = 32'h00112023;
        uut.itcm_inst.mem[3] = 32'h00012183;
        uut.itcm_inst.mem[4] = 32'h00012283;
        uut.itcm_inst.mem[5] = 32'h45600093;
        uut.itcm_inst.mem[6] = 32'h00112823;
        uut.itcm_inst.mem[7] = 32'h01012303;
        uut.itcm_inst.mem[8] = 32'h0000000b;

        $display("--- RISC-V CPU + Cache Integration Test ---");
        $monitor("Time=%0t | PC=%h | Instr=%h | x3=%h | x5=%h | x6=%h | Stall=%b", 
                 $time, uut.cpu.pc, uut.cpu.instr_in, 
                 uut.cpu.rf.gp_regs[3].reg_inst.q,
                 uut.cpu.rf.gp_regs[5].reg_inst.q,
                 uut.cpu.rf.gp_regs[6].reg_inst.q,
                 stall_cpu);
        
        clk = 0;
        rst = 1;
        #20 rst = 0;

        #5000; // Increased timeout for cache misses
        
        $display("Final Verification:");
        $display("x3 (0x2000_0000 load):     %h", uut.cpu.rf.gp_regs[3].reg_inst.q);
        $display("x5 (0x2000_0000 re-load):  %h", uut.cpu.rf.gp_regs[5].reg_inst.q);
        $display("x6 (0x2000_0010 load):     %h", uut.cpu.rf.gp_regs[6].reg_inst.q);
        
        if (uut.cpu.rf.gp_regs[3].reg_inst.q == 32'h00000123 && 
            uut.cpu.rf.gp_regs[5].reg_inst.q == 32'h00000123 &&
            uut.cpu.rf.gp_regs[6].reg_inst.q == 32'h00000456)
            $display("PASS: Cache integration verified.");
        else
            $display("FAIL: Cache data mismatch.");
            
        $finish;
    end
endmodule
