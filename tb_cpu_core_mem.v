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
        $display(".2 — CPU Core + Memory Integration Test");
        $monitor("Time=%0t | PC=%h | Instr=%h | R1=%h | R2=%h | R5=%h | R6=%h | dmem_addr=%h | ram_sel=%b | ram_rd=%h | ram_we=%b", 
                 $time, uut.cpu.pc, uut.cpu.instr_in, 
                 uut.cpu.rf.banks[0].bank_inst.bank[1].r.q,
                 uut.cpu.rf.banks[0].bank_inst.bank[2].r.q,
                 uut.cpu.rf.banks[0].bank_inst.bank[5].r.q,
                 uut.cpu.rf.banks[0].bank_inst.bank[6].r.q,
                 uut.cpu.dmem_addr, uut.ram_sel_d, uut.ram_rd_data, uut.ram_we_d);
        rst = 1;
        #20 rst = 0;

        #500;

        $display("Final Register Verification:");
        $display("R5 (exp CAFEBABE): %h", uut.cpu.rf.banks[0].bank_inst.bank[5].r.q);
        $display("R6 (exp 68100001): %h", uut.cpu.rf.banks[0].bank_inst.bank[6].r.q);
        
        if (uut.cpu.rf.banks[0].bank_inst.bank[5].r.q == 32'hCAFEBABE &&
            uut.cpu.rf.banks[0].bank_inst.bank[6].r.q == 32'h68100001)
            $display("PASS: .2 Memory Integration test successful!");
        else
            $display("FAIL: .2 Verification mismatch.");

        $finish;
    end

endmodule
