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
        // --- TEST DATA: Array A and B ---
        uut.main_ram.mem[0] = 32'd1;
        uut.main_ram.mem[1] = 32'd2;
        uut.main_ram.mem[2] = 32'd3;
        uut.main_ram.mem[3] = 32'd4;
        uut.main_ram.mem[4] = 32'd5;
        uut.main_ram.mem[5] = 32'd10;
        uut.main_ram.mem[6] = 32'd20;
        uut.main_ram.mem[7] = 32'd30;
        uut.main_ram.mem[8] = 32'd40;
        uut.main_ram.mem[9] = 32'd50;

        // --- TEST PROGRAM: Array Addition ---
        // 0x00: LUI  R1, 0x20000    ; Base A (0x2000_0000)
        // 0x04: ADDI R2, R1, 20     ; Base B (0x2000_0014)
        // 0x08: ADDI R3, R1, 40     ; Base C (0x2000_0028)
        // 0x0C: ADDI R4, R0, 5      ; N = 5
        // 0x10: LW   R5, 0(R1)      ; Loop Start
        // 0x14: LW   R6, 0(R2)
        // 0x18: ADD  R7, R5, R6
        // 0x1C: SW   R7, 0(R3)
        // 0x20: ADDI R1, R1, 4
        // 0x24: ADDI R2, R2, 4
        // 0x28: ADDI R3, R3, 4
        // 0x2C: SUBI R4, R4, 1
        // 0x30: BNE  R4, R0, -32    ; Jump back to 0x10 (Offset -32)
        // 0x34: HLT
        
        uut.main_rom.mem[0] = 32'h68120000; // LUI  x1, 0x20000
        uut.main_rom.mem[1] = 32'h40204014; // ADDI x2, x1, 20
        uut.main_rom.mem[2] = 32'h40304028; // ADDI x3, x1, 40
        uut.main_rom.mem[3] = 32'h40400005; // ADDI x4, x0, 5
        uut.main_rom.mem[4] = 32'h80504000; // LW   x5, 0(x1)
        uut.main_rom.mem[5] = 32'h80608000; // LW   x6, 0(x2)
        uut.main_rom.mem[6] = 32'h04714600; // ADD  x7, x5, x6
        uut.main_rom.mem[7] = 32'h8470c000; // SW   x7, 0(x3)
        uut.main_rom.mem[8] = 32'h40104004; // ADDI x1, x1, 4
        uut.main_rom.mem[9] = 32'h40208004; // ADDI x2, x2, 4
        uut.main_rom.mem[10] = 32'h4030c004; // ADDI x3, x3, 4
        uut.main_rom.mem[11] = 32'h44410001; // SUBI x4, x4, 1
        uut.main_rom.mem[12] = 32'hc4013ff7; // BNE  x4, x0, LOOP
        uut.main_rom.mem[13] = 32'hfc000000; // HLT

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
    initial begin
        $monitor("Time=%0t | PC=%h | Instr=%h | R1=%h | R4=%d | R7=%d | Br=%b | BrTgt=%h | Stall=%b", 
                 $time, uut.cpu.pc, uut.cpu.instr_in, 
                 uut.cpu.rf.gp_regs[1].reg_inst.q,
                 uut.cpu.rf.gp_regs[4].reg_inst.q,
                 uut.cpu.rf.gp_regs[7].reg_inst.q,
                 uut.cpu.take_branch, uut.cpu.branch_target, stall_cpu);
    end

endmodule
