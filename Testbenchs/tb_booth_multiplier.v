`timescale 1ns / 1ps

module tb_booth_multiplier;
    reg clk, rst, start;
    reg [31:0] a, b;
    reg a_signed, b_signed;
    wire [63:0] product;
    wire done;

    booth_multiplier uut (clk, rst, start, a, b, a_signed, b_signed, product, done);


    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 1; start = 0; a_signed = 1; b_signed = 1;
        #15 rst = 0;

        $display("Starting Sequential Multiplier Tests...");

        // 1. Signed x Signed
        run_mul(32'd10, 32'd20, 1, 1, "10 x 20 (S*S)");
        run_mul(32'hFFFFFFFF, 32'd42, 1, 1, "-1 x 42 (S*S)");
        run_mul(32'hFFFFFFFF, 32'hFFFFFFFF, 1, 1, "-1 x -1 (S*S)");

        // 2. Unsigned x Unsigned
        run_mul(32'hFFFFFFFF, 32'd1, 0, 0, "MAX_U x 1 (U*U)");
        run_mul(32'hFFFFFFFF, 32'hFFFFFFFF, 0, 0, "MAX_U x MAX_U (U*U)");

        // 3. Signed x Unsigned (MULHSU)
        run_mul(32'hFFFFFFFF, 32'd1, 1, 0, "-1 x 1 (S*U)");

        $finish;
    end

    task run_mul(input [31:0] in_a, input [31:0] in_b, input s_a, input s_b, input [120:1] label);
        begin
            a = in_a; b = in_b; a_signed = s_a; b_signed = s_b;
            start = 1;
            @(posedge clk);
            while(!done) @(posedge clk);
            start = 0;
            if (s_a && s_b)
                $display("[%s] A:%d * B:%d = %0d", label, $signed(a), $signed(b), $signed(product));
            else
                $display("[%s] A:%h * B:%h = %h", label, a, b, product);
            @(posedge clk);
        end
    endtask

endmodule
