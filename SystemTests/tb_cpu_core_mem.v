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
        // --- TEST PROGRAM: Memory Integration ---
        // 0x00: ADDI R1, R0, 0x123  ; R1 = 0x123
        // 0x04: LUI  R2, 0x20000    ; R2 = 0x20000000 (RAM Base)
        // 0x08: SW   R1, 0(R2)      ; RAM[0] = 0x123
        // 0x0C: LW   R3, 0(R2)      ; R3 = RAM[0]
        // 0x10: ADDI R1, R0, 0x456  ; R1 = 0x456
        // 0x14: SW   R1, 4(R2)      ; RAM[1] = 0x456
        // 0x18: LW   R5, 4(R2)      ; R5 = RAM[1]
        // 0x1C: HLT                 ; Halt
        
        uut.itcm_inst.mem[0] = 32'h40100123;
        uut.itcm_inst.mem[1] = 32'h68210000;
        uut.itcm_inst.mem[2] = 32'h84108000;
        uut.itcm_inst.mem[3] = 32'h80308000;
        uut.itcm_inst.mem[4] = 32'h40100456;
        uut.itcm_inst.mem[5] = 32'h84108004;
        uut.itcm_inst.mem[6] = 32'h80508004;
        uut.itcm_inst.mem[7] = 32'hFC000000;

        $display(".2 — CPU Core + Memory Integration Test");
        $monitor("Time=%0t | PC=%h | Instr=%h | R3=%h | R5=%h | ram_we=%b", 
                 $time, uut.cpu.pc, uut.cpu.instr_in, 
                 uut.cpu.rf.gp_regs[3].reg_inst.q,
                 uut.cpu.rf.gp_regs[5].reg_inst.q,
                 uut.ram_we_d);
        rst = 1;
        #20 rst = 0;

        #500;

        $display("Final Register Verification:");
        $display("R3 (exp 0123): %h", uut.cpu.rf.gp_regs[3].reg_inst.q);
        $display("R5 (exp 0456): %h", uut.cpu.rf.gp_regs[5].reg_inst.q);
        
        if (uut.cpu.rf.gp_regs[3].reg_inst.q == 32'h00000123 &&
            uut.cpu.rf.gp_regs[5].reg_inst.q == 32'h00000456)
            $display("PASS: .2 Memory Integration test successful!");
        else
            $display("FAIL: .2 Verification mismatch.");

        $finish;
    end

endmodule
