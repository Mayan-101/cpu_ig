`timescale 1ns / 1ps

module tb_divider;
    reg clk, rst, start;
    reg [31:0] dividend, divisor;
    wire [31:0] quotient, remainder;
    wire done, div_zero;

    divider uut (clk, rst, start, dividend, divisor, quotient, remainder, done, div_zero);

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 1; start = 0;
        #15 rst = 0;

        $display("Starting Sequential Divider Tests...");

        run_div(32'd10, 32'd2, "10 / 2");
        run_div(32'd10, 32'd3, "10 / 3");
        run_div(32'd0,  32'd42, "0 / N");
        run_div(32'd99, 32'd1, "N / 1");
        run_div(32'd45, 32'd45, "N / N");
        
        $display("\nTesting Div by Zero...");
        run_div(32'd100, 32'd0, "N / 0");

        $finish;
    end

    task run_div(input [31:0] num, input [31:0] den, input [80:1] label);
        begin
            dividend = num; divisor = den;
            start = 1;
            @(posedge clk);
            while(!done) @(posedge clk);
            start = 0;
            
            if (div_zero)
                $display("[%s] %d / %d -> DIVIDE BY ZERO ERROR", label, num, den);
            else
                $display("[%s] %d / %d -> Quot: %d | Rem: %d", label, num, den, quotient, remainder);
            
            @(posedge clk);
        end
    endtask
endmodule
