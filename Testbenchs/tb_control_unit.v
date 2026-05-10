`include "defines.vh"
`timescale 1ns / 1ps

module tb_control_unit;

    reg [6:0] opcode;
    reg [2:0] funct3;
    reg [6:0] funct7;

    wire mem_read;
    wire mem_write;
    wire reg_write;
    wire branch;
    wire jump;
    wire is_float;
    wire is_io;
    wire [1:0] wb_src;
    wire alu_src;
    wire [2:0] ext_mode;
    wire is_reti;
    wire is_halt;

    control_unit dut (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .reg_write(reg_write),
        .branch(branch),
        .jump(jump),
        .is_float(is_float),
        .is_io(is_io),
        .wb_src(wb_src),
        .alu_src(alu_src),
        .ext_mode(ext_mode),
        .is_reti(is_reti),
        .is_halt(is_halt)
    );

    integer pass_count, fail_count;

    task check_ctrl;
        input [127:0] name;
        input mr, mw, rw, br, jm, fl, io;
        input [1:0] ws;
        input as;
        input [2:0] em;
        begin
            #1;
            if (mem_read !== mr || mem_write !== mw || reg_write !== rw || 
                branch !== br || jump !== jm || is_float !== fl || is_io !== io ||
                wb_src !== ws || alu_src !== as || ext_mode !== em) begin
                $display("FAIL: %s", name);
                if (mem_read  !== mr) $display("  mem_read: %b (exp %b)", mem_read, mr);
                if (mem_write !== mw) $display("  mem_write: %b (exp %b)", mem_write, mw);
                if (reg_write !== rw) $display("  reg_write: %b (exp %b)", reg_write, rw);
                if (branch    !== br) $display("  branch: %b (exp %b)", branch, br);
                if (jump      !== jm) $display("  jump: %b (exp %b)", jump, jm);
                if (is_io     !== io) $display("  is_io: %b (exp %b)", is_io, io);
                if (wb_src    !== ws) $display("  wb_src: %b (exp %b)", wb_src, ws);
                if (alu_src   !== as) $display("  alu_src: %b (exp %b)", alu_src, as);
                if (ext_mode  !== em) $display("  ext_mode: %b (exp %b)", ext_mode, em);
                fail_count = fail_count + 1;
            end else begin
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        $display("--- RISC-V Control Unit Test ---");

        // R-type ADD
        opcode = `OPC_OP; funct3 = `F3_ADD_SUB; funct7 = `F7_BASE;
        check_ctrl("ADD", 0, 0, 1, 0, 0, 0, 0, 2'b00, 0, 3'b000);

        // I-type ADDI
        opcode = `OPC_OP_IMM; funct3 = `F3_ADD_SUB; funct7 = 7'h00;
        check_ctrl("ADDI", 0, 0, 1, 0, 0, 0, 0, 2'b00, 1, 3'b000);

        // LW
        opcode = `OPC_LOAD; funct3 = `F3_LW; funct7 = 7'h00;
        check_ctrl("LW", 1, 0, 1, 0, 0, 0, 0, 2'b01, 1, 3'b000);

        // SW
        opcode = `OPC_STORE; funct3 = `F3_SW; funct7 = 7'h00;
        check_ctrl("SW", 0, 1, 0, 0, 0, 0, 0, 2'b00, 1, 3'b001);

        // BEQ
        opcode = `OPC_BRANCH; funct3 = `F3_BEQ; funct7 = 7'h00;
        check_ctrl("BEQ", 0, 0, 0, 1, 0, 0, 0, 2'b00, 0, 3'b010);

        // JAL
        opcode = `OPC_JAL; 
        check_ctrl("JAL", 0, 0, 1, 0, 1, 0, 0, 2'b10, 0, 3'b100);

        // JALR
        opcode = `OPC_JALR; funct3 = `F3_JALR;
        check_ctrl("JALR", 0, 0, 1, 0, 1, 0, 0, 2'b10, 1, 3'b000);

        // LUI
        opcode = `OPC_LUI;
        check_ctrl("LUI", 0, 0, 1, 0, 0, 0, 0, 2'b00, 1, 3'b011);

        // CUSTOM0: HLT
        opcode = `OPC_CUSTOM0; funct3 = `F3_HLT;
        #1;
        if (is_halt !== 1) begin $display("FAIL: HLT"); fail_count = fail_count + 1; end
        else pass_count = pass_count + 1;

        // CUSTOM0: IN
        opcode = `OPC_CUSTOM0; funct3 = `F3_IN;
        check_ctrl("IN", 0, 0, 1, 0, 0, 0, 1, 2'b11, 1, 3'b000);

        $display("--- Results: %0d PASS, %0d Errors ---", pass_count, fail_count);
        if (fail_count == 0) $display("SUCCESS"); else $display("FAILURE");
        $finish;
    end

endmodule
