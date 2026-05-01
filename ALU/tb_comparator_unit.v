`timescale 1ns / 1ps

module tb_comparator_unit;

    reg [31:0] a, b;
    reg        signed_mode;
    wire       eq, lt, gt;

    comparator_unit uut (a, b, signed_mode, eq, lt, gt);

    initial begin
        $display("Starting Comparator Unit Tests...");
        $display(" Mode | Input A  | Input B  | EQ | LT | GT | Valid?");
        $display("-----------------------------------------------------");

        // Case 1: Equality
        a = 32'hFEEDFACE; b = 32'hFEEDFACE; signed_mode = 0; #10;
        check_exclusive("Equal");

        // Case 2: Signed -1 < 1
        // 0xFFFFFFFF is -1 in signed
        a = 32'hFFFFFFFF; b = 32'h00000001; signed_mode = 1; #10;
        check_exclusive("Signed LT");

        // Case 3: Unsigned 0xFFFFFFFF > 1
        a = 32'hFFFFFFFF; b = 32'h00000001; signed_mode = 0; #10;
        check_exclusive("Unsigned GT");

        // Case 4: Signed mode, positive > negative
        a = 32'h00000005; b = 32'hFFFFFFFB; signed_mode = 1; #10;
        check_exclusive("Pos > Neg");

        $finish;
    end

    task check_exclusive(input [80:1] label);
        integer sum_flags;
        begin
            sum_flags = eq + lt + gt;
            $display(" %s | %h | %h | %b  | %b  | %b  | %s", 
                     (signed_mode ? "SGN " : "UNS "), a, b, eq, lt, gt, 
                     (sum_flags == 1 ? "PASS" : "FAIL"));
        end
    endtask

endmodule