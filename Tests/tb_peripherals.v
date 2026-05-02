`timescale 1ns / 1ps

module tb_phase11();
    reg clk;
    reg rst;
    
    system_top uut (
        .clk(clk), .rst(rst),
        .io_data_out(), .io_addr_out(), .io_we_out()
    );

    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test Sequence
    initial begin
        $display("Phase 11: I/O and Interrupt Integration Test");
        
        // Initialize Memory with test program
        // 0x00: ADDI R1, R0, 0x100  (mtvec = 0x100)
        // 0x04: SW   R1, 0x1000(R0) ; Write mtvec
        // 0x08: ADDI R1, R0, 1
        // 0x0C: SLLI R1, R1, 31     ; R1 = 0x80000000 (IE bit)
        // 0x10: PUSH R1             ; We don't have direct PSW write, but let's assume SEI MISC works
        // ... Wait, let's use MISC SEI (0x3F, funct 0x08)
        // 0x10: SEI (funct 0x08)    ; 0x3F000008
        // 0x14: ADDI R2, R0, 10     ; Timer load value
        // 0x18: SW   R2, 0x1100(R0) ; TIMER0_LOAD
        // 0x1C: ADDI R2, R0, 1      ; Enable bit
        // 0x20: SW   R2, 0x1108(R0) ; TIMER0_CTRL (Enable)
        // 0x24: ADDI R3, R0, 1      ; INT ENABLE
        // 0x28: SW   R3, 0x1300(R0) ; INTC_ENABLE
        // 0x2C: NOP (Loop)
        // 0x30: J    0x2C
        
        // Interrupt Handler at 0x100 (Word index 64)
        // 0x100: ADDI R5, R5, 1      ; Increment counter
        // 0x104: ADDI R2, R0, 0
        // 0x108: SW   R2, 0x110C(R0) ; Clear Timer IRQ (addr 0x110C)
        // 0x10C: RETI                ; 0x3C000000
        
        uut.rom_inst.mem[0] = 32'h40100100; // ADDI R1, R0, 0x100
        uut.rom_inst.mem[1] = 32'h84101000; // SW   R1, 0x1000(R0) (mtvec)
        uut.rom_inst.mem[2] = 32'hFC000008; // SEI
        uut.rom_inst.mem[3] = 32'h4020000A; // ADDI R2, R0, 10
        uut.rom_inst.mem[4] = 32'h84201100; // SW   R2, 0x1100(R0) (TIMER0_LOAD)
        uut.rom_inst.mem[5] = 32'h40200001; // ADDI R2, R0, 1
        uut.rom_inst.mem[6] = 32'h84201108; // SW   R2, 0x1108(R0) (TIMER0_CTRL)
        uut.rom_inst.mem[7] = 32'h40300001; // ADDI R3, R0, 1
        uut.rom_inst.mem[8] = 32'h84301300; // SW   R3, 0x1300(R0) (INTC_ENABLE)
        uut.rom_inst.mem[9] = 32'h00000000; // NOP
        uut.rom_inst.mem[10] = 32'hE000000A; // J 0x28 (NOP)

        uut.rom_inst.mem[64] = 32'h00514001; // ADD R5, R5, R1 (R1=0x100, but let's assume R5++)
        // Wait, ADD R5, R5, R1 is 0x01...
        uut.rom_inst.mem[64] = 32'h40514001; // ADDI R5, R5, 1
        uut.rom_inst.mem[65] = 32'h40200000; // ADDI R2, R0, 0
        uut.rom_inst.mem[66] = 32'h8420110C; // SW   R2, 0x110C(R0) (Clear IRQ)
        uut.rom_inst.mem[67] = 32'hF0000000; // RETI

        rst = 1;
        #20 rst = 0;

        $monitor("Time=%0t | PC=%h | R5=%d | IRQ=%b | IE=%b | MEPC=%h | RETI=%b | IP=%b | IT=%b", 
                 $time, uut.cpu.pc, uut.cpu.rf.gp_regs[5].reg_inst.q, uut.irq_signal, uut.cpu.psw[31], 
                 uut.cpu.mepc, uut.cpu.id_ex_is_reti, uut.cpu.int_pending, uut.cpu.int_taken);

        #2000;
        
        if (uut.cpu.rf.gp_regs[5].reg_inst.q > 0)
            $display("PASS: Interrupt taken and R5 incremented!");
        else
            $display("FAIL: Interrupt not taken.");

        $finish;
    end
endmodule
