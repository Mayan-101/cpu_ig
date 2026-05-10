`timescale 1ns / 1ps

module tb_peripherals();
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
        $display("--- RISC-V I/O and Interrupt Integration Test ---");
        
        // --- RISC-V TEST PROGRAM ---
        // 0x00: ADDI x1, x0, 0x100     ; x1 = 0x100 (Handler Address)
        // 0x04: LUI  x2, 0x80000       ; x2 = 0x80000000 (System Space)
        // 0x08: SW   x1, 0(x2)         ; mtvec = 0x100 (Address 0x80000000)
        // 0x0C: SEI                    ; Enable Interrupts
        // 0x10: LUI  x2, 0x40000       ; x2 = 0x40000000 (IO Space)
        // 0x14: ADDI x3, x0, 50        ; Timer Load = 50 cycles
        // 0x18: SW   x3, 0x100(x2)     ; TIMER0_LOAD
        // 0x1C: ADDI x3, x0, 1         ; Enable Bit
        // 0x20: SW   x3, 0x108(x2)     ; TIMER0_CTRL
        // 0x24: ADDI x3, x0, 1         ; INTC Enable Bit
        // 0x28: SW   x3, 0x300(x2)     ; INTC_ENABLE
        // 0x2C: J    0x2C              ; Infinite Loop
        
        uut.itcm_inst.mem[0] = 32'h10000093; 
        uut.itcm_inst.mem[1] = 32'h80000137;
        uut.itcm_inst.mem[2] = 32'h00112023;
        uut.itcm_inst.mem[3] = 32'h0000100b;
        uut.itcm_inst.mem[4] = 32'h40000137;
        uut.itcm_inst.mem[5] = 32'h03200193;
        uut.itcm_inst.mem[6] = 32'h10312023;
        uut.itcm_inst.mem[7] = 32'h00100193;
        uut.itcm_inst.mem[8] = 32'h10312423;
        uut.itcm_inst.mem[9] = 32'h00200193;
        uut.itcm_inst.mem[10] = 32'h30312023;
        uut.itcm_inst.mem[11] = 32'h0000006f;
        
        // --- INTERRUPT HANDLER (at 0x100) ---
        // 0x100: ADDI x5, x5, 1        ; Increment x5
        // 0x104: LUI  x2, 0x40000
        // 0x108: ADDI x3, x0, 0
        // 0x10C: SW   x3, 0x10C(x2)    ; Clear Timer IRQ
        // 0x110: RETI
        
        uut.itcm_inst.mem[64] = 32'h00128293;
        uut.itcm_inst.mem[65] = 32'h40000137;
        uut.itcm_inst.mem[66] = 32'h00000193;
        uut.itcm_inst.mem[67] = 32'h10312623;
        uut.itcm_inst.mem[68] = 32'h0030000b;

        rst = 1;
        #20 rst = 0;

        $monitor("Time=%0t | PC=%h | x5=%d | IRQ=%b | IE=%b | MEPC=%h | IT=%b", 
                 $time, uut.cpu.ibus_addr, uut.cpu.rf.gp_regs[5].reg_inst.q, uut.irq_signal, uut.cpu.mstatus[3], 
                 uut.cpu.mepc, uut.cpu.trap_taken);


        #10000; // Increased timeout for interrupt to trigger
        
        $display("Final Register Verification:");
        $display("x5 (IRQ count): %d", uut.cpu.rf.gp_regs[5].reg_inst.q);

        // Test Slot 5
        $display("Testing IO Slot 5 (0x40000400)...");
        // We can't easily force a load from here without writing more assembly, 
        // but we can check if the bus decoder works by looking at the wires.
        if (uut.io_bus.io_addr == 32'h40000400 && uut.io_bus.slot_sel[5])
             $display("Slot 5 Selected correctly.");


        if (uut.cpu.rf.gp_regs[5].reg_inst.q > 0)
            $display("SUCCESS: Interrupt taken and x5 incremented!");
        else
            $display("FAIL: Interrupt not taken.");

        $finish;
    end
endmodule

