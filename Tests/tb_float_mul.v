`timescale 1ns / 1ps

module tb_float_mul;
    reg [31:0] a, b;
    wire [31:0] res;
    wire of, uf;

    float_mul uut (a, b, res, of, uf);

    initial begin
        $display("Testing FPU Multiplier...");
        $display("---------------------------------------");

        // 2.0 (40000000) * 3.0 (40400000) = 6.0 (40C00000)
        a = 32'h40000000; b = 32'h40400000; #10;
        $display("2.0 * 3.0 = %h | Expected: 40C00000", res);

        // 1.0 * N = N
        a = 32'h3F800000; b = 32'h42280000; #10; // 1.0 * 42.0
        $display("1.0 * 42.0 = %h | Expected: 42280000", res);

        // 0.0 * N = 0.0
        a = 32'h00000000; b = 32'h40400000; #10;
        $display("0.0 * 3.0 = %h | Expected: 00000000", res);

        // INF * 1.0 = INF
        a = 32'h7F800000; b = 32'h3F800000; #10;
        $display("INF * 1.0 = %h | Expected: 7F800000", res);

        // Overflow check (Max Float * 2.0)
        a = 32'h7F7FFFFF; b = 32'h40000000; #10;
        $display("Overflow Test: %h | OF Flag: %b", res, of);

        $display("---------------------------------------");
        $finish;
    end
endmodule
