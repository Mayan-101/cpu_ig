`include "defines.vh"
`timescale 1ns / 1ps

module tb_alu_top;

    reg clk;
    reg rst;
    reg start;
    reg [31:0] a;
    reg [31:0] b;
    reg [6:0]  opcode;
    reg [2:0]  funct3;
    reg [6:0]  funct7;
    reg        is_float;
    wire [31:0] result;
    wire done;
    wire [31:0] psw_out;

    alu_top dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .a(a),
        .b(b),
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .result(result),
        .done(done),
        .psw_out(psw_out)
    );

    always #5 clk = ~clk;

    integer errors = 0;
    integer cycle_count;

    initial begin
        clk = 0;
        rst = 1;
        start = 0;
        a = 0;
        b = 0;
        opcode = 0;
        funct3 = 0;
        funct7 = 0;
        
        #15 rst = 0;
        
        // 1. Issue ADD (OPC_OP)
        @(posedge clk);
        a = 32'd10; b = 32'd20; 
        opcode = `OPC_OP; funct3 = `F3_ADD_SUB; funct7 = `F7_BASE; 
        start = 1;
        #1; // combinational
        if (result !== 32'd30 || done !== 1'b1) begin
            $display("ERROR: ADD failed. res=%0d (exp: 30), done=%b", result, done);
            errors = errors + 1;
        end else begin
            $display("ADD passed. 1 cycle (combinational) done.");
        end
        start = 0;
        while(done) #1; 

        // 2. Issue MUL (OPC_OP + MULDIV)
        @(posedge clk);
        a = 32'd5; b = 32'd6; 
        opcode = `OPC_OP; funct3 = `F3_MUL; funct7 = `F7_MULDIV;
        start = 1;
        #1;
        cycle_count = 0;
        while (!done) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
        end
        if (result !== 32'd30) begin
            $display("ERROR: MUL failed. res=%0d (exp: 30)", result);
            errors = errors + 1;
        end else begin
            $display("MUL passed. cycles=%0d", cycle_count);
        end
        start = 0;
        while(done) @(posedge clk);

        // 3. Issue DIV
        @(posedge clk);
        a = 32'd100; b = 32'd10; 
        opcode = `OPC_OP; funct3 = `F3_DIV; funct7 = `F7_MULDIV;
        start = 1;
        #1;
        cycle_count = 0;
        while (!done) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
        end
        if (result !== 32'd10) begin
            $display("ERROR: DIV failed. res=%0d (exp: 10)", result);
            errors = errors + 1;
        end else begin
            $display("DIV passed. cycles=%0d", cycle_count);
        end
        start = 0;
        while (done) @(posedge clk);

        if (errors == 0)
            $display("tb_alu_top PASSED.");
        else
            $display("tb_alu_top FAILED with %0d errors.", errors);
        $finish;
    end
endmodule

