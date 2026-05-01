`timescale 1ns / 1ps

module tb_float_norm;
    reg [47:0] raw_m;
    reg [8:0]  raw_e;
    wire [7:0] f_e;
    wire [22:0] f_m;
    wire uf, of;

    float_norm uut (raw_m, raw_e, f_e, f_m, uf, of);

    initial begin
        $display("Testing Normalization Module...");

        // Case 1: Result is already normalized (leading one at bit 23)
        raw_m = 48'h000000_800000; raw_e = 8'd127; #10;
        $display("Normalized: Exp=%d, Mant=%h", f_e, f_m);

        // Case 2: Result needs right shift (e.g., after addition carry)
        raw_m = 48'h000000_F00000; raw_e = 8'd127; #10;
        $display("Right Shift: Exp=%d, Mant=%h", f_e, f_m);

        // Case 3: Result needs left shift (e.g., after subtraction cancellation)
        raw_m = 48'h000000_000001; raw_e = 8'd127; #10;
        $display("Left Shift:  Exp=%d, Mant=%h", f_e, f_m);

        $finish;
    end
endmodule