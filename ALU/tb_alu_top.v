`timescale 1ns / 1ps

module tb_alu_top;

    reg clk;
    reg rst;
    reg start;
    reg [31:0] a;
    reg [31:0] b;
    reg [5:0]  op;
    wire [31:0] result;
    wire done;
    wire [3:0] int_flags;
    wire [2:0] fp_flags;

    alu_top dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .a(a),
        .b(b),
        .op(op),
        .result(result),
        .done(done),
        .int_flags(int_flags),
        .fp_flags(fp_flags)
    );

    always #5 clk = ~clk;

    localparam OP_ADD  = 6'b000000;
    localparam OP_MUL  = 6'b010000;
    localparam OP_DIV  = 6'b010001;
    localparam OP_FADD = 6'b100000;

    integer errors = 0;
    integer cycle_count;

    initial begin
        clk = 0;
        rst = 1;
        start = 0;
        a = 0;
        b = 0;
        op = 0;
        
        #15 rst = 0;
        
        // 1. Issue ADD
        @(posedge clk);
        a = 32'd10; b = 32'd20; op = OP_ADD; start = 1;
        #1; // combinational
        if (result !== 32'd30 || done !== 1'b1) begin
            $display("ERROR: ADD failed. res=%0d (exp: 30), done=%b", result, done);
            errors = errors + 1;
        end else begin
            $display("ADD passed. 1 cycle (combinational) done.");
        end
        start = 0;
        while(done) #1; // Wait for combinational done to drop since start=0

        // 2. Issue MUL
        @(posedge clk);
        a = 32'd5; b = 32'd6; op = OP_MUL; start = 1;
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

        // 3. Issue FADD
        @(posedge clk);
        // 1.0 (3f800000) + 1.0 (3f800000) = 2.0 (40000000)
        a = 32'h3f800000; b = 32'h3f800000; op = OP_FADD; start = 1;
        #1; // combinational
        if (result !== 32'h40000000 || done !== 1'b1) begin
            $display("ERROR: FADD failed. res=%h (exp: 40000000), done=%b", result, done);
            errors = errors + 1;
        end else begin
            $display("FADD passed. combinational done.");
        end
        start = 0;
        while(done) #1;

        // 4. Issue DIV
        @(posedge clk);
        a = 32'd100; b = 32'd10; op = OP_DIV; start = 1;
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
        while (done) @(posedge clk); // wait for done to de-assert

        // 5. Back-to-back mul then div
        @(posedge clk);
        a = 32'd7; b = 32'd8; op = OP_MUL; start = 1;
        #1; // allow comb logic to settle
        cycle_count = 0;
        while (!done) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
        end
        if (result !== 32'd56) begin
            $display("ERROR: Back-to-back MUL failed. res=%0d (exp: 56), cycles=%0d", result, cycle_count);
            errors = errors + 1;
        end
        start = 0;
        while (done) @(posedge clk);

        @(posedge clk);
        a = 32'd56; b = 32'd7; op = OP_DIV; start = 1;
        #1;
        while (!done) @(posedge clk);
        if (result !== 32'd8) begin
            $display("ERROR: Back-to-back DIV failed.");
            errors = errors + 1;
        end
        $display("Back-to-back MUL then DIV passed.");
        start = 0;
        while (done) @(posedge clk);

        if (errors == 0)
            $display("tb_alu_top PASSED.");
        else
            $display("tb_alu_top FAILED with %0d errors.", errors);
        $finish;
    end

endmodule
