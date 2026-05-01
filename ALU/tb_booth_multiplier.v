`timescale 1ns / 1ps

module tb_booth_multiplier;
    reg clk, rst, start;
    reg [31:0] a, b;
    wire [63:0] product;
    wire done;

    booth_multiplier uut (clk, rst, start, a, b, product, done);

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 1; start = 0;
        #15 rst = 0;

        $display("Starting Sequential Multiplier Tests...");

        // 1. 0 x N = 0
        run_mul(32'd0, 32'd42, "0 x 42");
        // 2. N x 0 = 0
        run_mul(32'd99, 32'd0, "99 x 0");
        // 3. 1 x N = N
        run_mul(32'd1, 32'd500, "1 x 500");
        // 4. (-1) x N = -N
        run_mul(32'hFFFFFFFF, 32'd42, "-1 x 42");
        // 5. 255 x 255 = 65025
        run_mul(32'd255, 32'd255, "255 x 255");
        // 6. MAX_INT x MAX_INT
        run_mul(32'h7FFFFFFF, 32'h7FFFFFFF, "MAX x MAX");

        $finish;
    end

    task run_mul(input [31:0] in_a, input [31:0] in_b, input [80:1] label);
        begin
            a = in_a; b = in_b;
            start = 1;
            @(posedge clk);
            while(!done) @(posedge clk);
            start = 0;
            $display("[%s] A:%d * B:%d = %0d (Hex: %h)", label, $signed(a), $signed(b), $signed(product), product);
            @(posedge clk);
        end
    endtask
endmodule
