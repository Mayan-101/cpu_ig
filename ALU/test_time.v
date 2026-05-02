`timescale 1ns/1ps
module tb;
    initial begin
        $display("START at T=%0t", $time);
        #1000;
        $display("DONE at T=%0t", $time);
        $finish;
    end
endmodule
