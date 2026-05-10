`timescale 1ns / 1ps

module tb_cpu_core_mem();

    reg clk;
    reg rst;
    
    wire [31:0] io_data_out;
    wire [15:0] io_addr_out;
    wire io_we_out;

    system_top uut (
        .clk(clk), .rst(rst),
        .io_data_out(io_data_out), .io_addr_out(io_addr_out), .io_we_out(io_we_out)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        // --- RISC-V TEST PROGRAM: Memory Integration ---
        // 0x00: ADDI x1, x0, 0x123
        // 0x04: LUI  x2, 0x20000    (x2 = 0x20000000)
        // 0x08: SW   x1, 0(x2)
        // 0x0C: LW   x3, 0(x2)
        // 0x10: ADDI x1, x0, 0x456
        // 0x14: SW   x1, 4(x2)
        // 0x18: LW   x5, 4(x2)
        // 0x1C: HLT
        
        uut.itcm_inst.mem[0] = 32'h12300093;
        uut.itcm_inst.mem[1] = 32'h10000137;
        uut.itcm_inst.mem[2] = 32'h00112023;
        uut.itcm_inst.mem[3] = 32'h00012183;
        uut.itcm_inst.mem[4] = 32'h45600093;
        uut.itcm_inst.mem[5] = 32'h00112223;
        uut.itcm_inst.mem[6] = 32'h00412283;
        uut.itcm_inst.mem[7] = 32'h0000000b;

        $display("--- RISC-V CPU Core + Memory Integration Test ---");
        $monitor("Time=%0t | PC=%h | Instr=%h | x3=%h | x5=%h | ram_we=%b", 
                 $time, uut.cpu.ibus_addr, uut.cpu.ibus_rdata, 
                 uut.cpu.rf.gp_regs[3].reg_inst.q,
                 uut.cpu.rf.gp_regs[5].reg_inst.q,
                 uut.ram_we_d);

        rst = 1;
        #20 rst = 0;

        #1000;

        $display("Final Register Verification:");
        $display("x3 (exp 0123): %h", uut.cpu.rf.gp_regs[3].reg_inst.q);
        $display("x5 (exp 0456): %h", uut.cpu.rf.gp_regs[5].reg_inst.q);
        
        if (uut.cpu.rf.gp_regs[3].reg_inst.q == 32'h00000123 &&
            uut.cpu.rf.gp_regs[5].reg_inst.q == 32'h00000456)
            $display("PASS: Memory Integration test successful!");
        else
            $display("FAIL: Verification mismatch.");

        $finish;
    end

endmodule
