`timescale 1ns / 1ps

module tb_control_unit;

    reg [5:0] opcode;
    reg [7:0] funct;
    
    wire [5:0] alu_op;
    wire mem_read;
    wire mem_write;
    wire reg_write;
    wire branch;
    wire jump;
    wire is_float;
    wire is_io;
    wire [1:0] wb_src;
    wire alu_src;
    wire [1:0] ext_mode;

    control_unit dut (
        .opcode(opcode),
        .funct(funct),
        .alu_op(alu_op),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .reg_write(reg_write),
        .branch(branch),
        .jump(jump),
        .is_float(is_float),
        .is_io(is_io),
        .wb_src(wb_src),
        .alu_src(alu_src),
        .ext_mode(ext_mode)
    );

    task check_ctrl;
        input [63:0] name;
        input mr, mw, rw, br, jm, fl, io;
        input [1:0] ws;
        input as;
        input [1:0] em;
        begin
            #1;
            $display("Test: %s", name);
            if (mem_read !== mr) $display("  FAIL: mem_read %b != %b", mem_read, mr);
            if (mem_write !== mw) $display("  FAIL: mem_write %b != %b", mem_write, mw);
            if (reg_write !== rw) $display("  FAIL: reg_write %b != %b", reg_write, rw);
            if (branch !== br) $display("  FAIL: branch %b != %b", branch, br);
            if (jump !== jm) $display("  FAIL: jump %b != %b", jump, jm);
            if (is_float !== fl) $display("  FAIL: is_float %b != %b", is_float, fl);
            if (is_io !== io) $display("  FAIL: is_io %b != %b", is_io, io);
            if (wb_src !== ws) $display("  FAIL: wb_src %b != %b", wb_src, ws);
            if (alu_src !== as) $display("  FAIL: alu_src %b != %b", alu_src, as);
            if (ext_mode !== em) $display("  FAIL: ext_mode %b != %b", ext_mode, em);
        end
    endtask

    initial begin
        $display("--- M9.4: Control Unit Test ---");
        
        // Test: ADD (0x01)
        opcode = 6'h01; funct = 8'h00;
        check_ctrl("ADD", 0, 0, 1, 0, 0, 0, 0, 2'b00, 0, 2'b00);
        
        // Test: LW (0x20)
        opcode = 6'h20; funct = 8'h00;
        check_ctrl("LW", 1, 0, 1, 0, 0, 0, 0, 2'b01, 1, 2'b00);

        // Test: SW (0x21)
        opcode = 6'h21; funct = 8'h00;
        check_ctrl("SW", 0, 1, 0, 0, 0, 0, 0, 2'b00, 1, 2'b00);

        // Test: BEQ (0x30)
        opcode = 6'h30; funct = 8'h00;
        check_ctrl("BEQ", 0, 0, 0, 1, 0, 0, 0, 2'b00, 0, 2'b00);

        // Test: JAL (0x38)
        opcode = 6'h38; funct = 8'h00;
        check_ctrl("JAL", 0, 0, 0, 0, 1, 0, 0, 2'b00, 0, 2'b10);

        // Test: FADD (0x28)
        opcode = 6'h28; funct = 8'h00;
        check_ctrl("FADD", 0, 0, 1, 0, 0, 1, 0, 2'b00, 0, 2'b00);

        // Test: OUT (0x3E)
        opcode = 6'h3E; funct = 8'h00;
        check_ctrl("OUT", 0, 0, 0, 0, 0, 0, 1, 2'b00, 1, 2'b01);
        
        $display("Test finished.");
        $finish;
    end

endmodule
