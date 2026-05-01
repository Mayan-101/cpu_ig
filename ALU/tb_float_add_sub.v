`timescale 1ns / 1ps

module tb_float_add_sub;
    reg [31:0] a, b;
    reg op;
    wire [31:0] res;

    float_add_sub uut (a, b, op, res, , );

    initial begin
        $display("Testing FPU Add/Sub...");
        
        // 1.0 + 1.0 = 2.0 (0x40000000)
        a = 32'h3F800000; b = 32'h3F800000; op = 0; #10;
        $display("1.0 + 1.0 = %h", res);

        // 1.5 - 0.5 = 1.0 (0x3F800000)
        a = 32'h3FC00000; b = 32'h3F000000; op = 1; #10;
        $display("1.5 - 0.5 = %h", res);

        // INF + 1.0 = INF
        a = 32'h7F800000; b = 32'h3F800000; op = 0; #10;
        $display("INF + 1.0 = %h", res);

        // Cancellation: 1.0 - 1.0 = 0
        a = 32'h3F800000; b = 32'h3F800000; op = 1; #10;
        $display("1.0 - 1.0 = %h", res);

        $finish;
    end
endmodule