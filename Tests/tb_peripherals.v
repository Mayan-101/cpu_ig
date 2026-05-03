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
        
        // --- TEST PROGRAM ---
        // 0x00: ADDI R1, R0, 0x100     ; R1 = 0x100 (Handler Address)
        // 0x04: LUI  R2, 0x80000     ; R2 = 0x80000000 (System Space)
        // 0x08: SW   R1, 0(R2)         ; mtvec = 0x100 (Address 0x80000000)
        // 0x0C: SEI (MISC funct 0x08)  ; Enable Interrupts
        // 0x10: LUI  R2, 0x40000     ; R2 = 0x40000000 (IO Space)
        // 0x14: ADDI R3, R0, 50        ; Timer Load = 50 cycles
        // 0x18: SW   R3, 0x100(R2)     ; TIMER0_LOAD (Addr 0x40000100)
        // 0x1C: ADDI R3, R0, 1         ; Enable Bit
        // 0x20: SW   R3, 0x108(R2)     ; TIMER0_CTRL (Addr 0x40000108)
        // 0x24: ADDI R3, R0, 1         ; INTC Enable Bit
        // 0x28: SW   R3, 0x300(R2)     ; INTC_ENABLE (Addr 0x40000300)
        // 0x2C: J    0x2C              ; Infinite Loop at 0x2C
        
        uut.rom_inst.mem[0] = 32'h40100100; // ADDI R1, R0, 0x100
        uut.rom_inst.mem[1] = 32'h68280000; // LUI  R2, 0x80000
        uut.rom_inst.mem[2] = 32'h84108000; // SW   R1, 0(R2)
        uut.rom_inst.mem[3] = 32'hFC000008; // SEI
        uut.rom_inst.mem[4] = 32'h68240000; // LUI  R2, 0x40000
        uut.rom_inst.mem[5] = 32'h40300032; // ADDI R3, R0, 50
        uut.rom_inst.mem[6] = 32'h84308400; // SW   R3, 0x100(R2)
        uut.rom_inst.mem[7] = 32'h40300001; // ADDI R3, R0, 1
        uut.rom_inst.mem[8] = 32'h84308420; // SW   R3, 0x108(R2)
        uut.rom_inst.mem[9] = 32'h40300001; // ADDI R3, R0, 1
        uut.rom_inst.mem[10] = 32'h84308C00; // SW   R3, 0x300(R2)
        uut.rom_inst.mem[11] = 32'hE000002C; // J 0x2C
        
        // --- INTERRUPT HANDLER (at 0x100) ---
        // 0x100: ADDI R5, R5, 1        ; Increment R5
        // 0x104: LUI  R2, 0x40000
        // 0x108: ADDI R3, R0, 0
        // 0x10C: SW   R3, 0x10C(R2)    ; Clear Timer IRQ (Addr 0x4000010C)
        // 0x110: RETI
        
        uut.rom_inst.mem[64] = 32'h40514001; // ADDI R5, R5, 1
        uut.rom_inst.mem[65] = 32'h68240000; // LUI  R2, 0x40000
        uut.rom_inst.mem[66] = 32'h40300000; // ADDI R3, R0, 0
        uut.rom_inst.mem[67] = 32'h84308430; // SW   R3, 0x10C(R2)
        uut.rom_inst.mem[68] = 32'hF0000000; // RETI

        rst = 1;
        #20 rst = 0;

        $monitor("Time=%0t | PC=%h | R5=%d | IRQ=%b | IE=%b | MEPC=%h | IT=%b", 
                 $time, uut.cpu.pc, uut.cpu.rf.gp_regs[5].reg_inst.q, uut.irq_signal, uut.cpu.psw[31], 
                 uut.cpu.mepc, uut.cpu.int_taken);

        #5000;
        
        if (uut.cpu.rf.gp_regs[5].reg_inst.q > 0)
            $display("PASS: Interrupt taken and R5 incremented!");
        else
            $display("FAIL: Interrupt not taken.");

        $finish;
    end
endmodule
