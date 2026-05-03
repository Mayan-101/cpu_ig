`timescale 1ns / 1ps

module tb_barrel_shifter;

    reg [31:0] a;
    reg [4:0]  shamt;
    reg [1:0]  shift_type;
    wire [31:0] result;
    wire        carry_out;

    barrel_shifter uut (a, shamt, shift_type, result, carry_out);

    initial begin
        $display("Starting Barrel Shifter Tests...");
        $display(" Type | Input A  | Amt | Result   | C ");
        $display("---------------------------------------");

        // Pattern 1: Identity and basic shifts (0, 1, 16, 31)
        a = 32'hA5A5A5A5;
        test_shift(a, 5'd0,  2'b00, "LSL");
        test_shift(a, 5'd1,  2'b00, "LSL");
        test_shift(a, 5'd16, 2'b00, "LSL");
        test_shift(a, 5'd31, 2'b00, "LSL");

        // Pattern 2: ASR vs LSR on negative number (0x80000001)
        a = 32'h80000001;
        $display("--- Comparison: ASR (Sign Extend) vs LSR (Zero Fill) ---");
        test_shift(a, 5'd4, 2'b01, "LSR"); // Expected: 08000000
        test_shift(a, 5'd4, 2'b10, "ASR"); // Expected: F8000000

        // Pattern 3: Rotate Right (ROR)
        a = 32'h12345678;
        test_shift(a, 5'd8, 2'b11, "ROR"); // Expected: 78123456

        $finish;
    end

    task test_shift(input [31:0] in_a, input [4:0] amt, input [1:0] t_mode, input [31:0] name);
        begin
            a = in_a; shamt = amt; shift_type = t_mode;
            #10;
            $display(" %s  | %h | %2d  | %h | %b", name, a, shamt, result, carry_out);
        end
    endtask

endmodule
