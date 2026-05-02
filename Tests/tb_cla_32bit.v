`timescale 1ns / 1ps

module tb_cla_32bit;

    // Inputs
    reg [31:0] a;
    reg [31:0] b;
    reg        cin;

    // Outputs
    wire [31:0] sum;
    wire        cout;
    wire        overflow;

    // Reference model signals for automated checking
    wire [32:0] ref_sum_full; 
    wire [31:0] ref_sum;
    wire        ref_cout;
    wire        ref_overflow;

    // Behavioral reference model
    assign ref_sum_full = a + b + cin;
    assign ref_sum      = ref_sum_full[31:0];
    assign ref_cout     = ref_sum_full[32];
    assign ref_overflow = (a[31] == b[31]) && (ref_sum[31] != a[31]);

    // Instantiate the Unit Under Test (UUT)
    cla_32bit uut (
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .cout(cout),
        .overflow(overflow)
    );

    integer i;
    integer error_count;

    initial begin
        error_count = 0;
        $display("Starting 32-bit CLA Tests...\n");

        // Test 1: MIN_INT + MIN_INT (Underflow/Overflow expected)
        // 0x80000000 + 0x80000000
        a = 32'h80000000; b = 32'h80000000; cin = 0;
        #10;
        check_results("MIN_INT + MIN_INT");

        // Test 2: MAX_INT + 1 (Overflow expected)
        // 0x7FFFFFFF + 0x00000001
        a = 32'h7FFFFFFF; b = 32'h00000001; cin = 0;
        #10;
        check_results("MAX_INT + 1");

        // Test 3: 0 + 0
        a = 32'h00000000; b = 32'h00000000; cin = 0;
        #10;
        check_results("0 + 0");

        // Test 4: 100 Random Signed/Unsigned Pairs
        for (i = 0; i < 100; i = i + 1) begin
            a = $random;      // $random generates a 32-bit signed integer
            b = $random;
            cin = $random % 2; // Random 0 or 1
            #10;
            check_results("Random Pair");
        end

        // Summary
        $display("\n-------------------------------------------------");
        if (error_count == 0)
            $display("SUCCESS: All 103 tests passed!");
        else
            $display("FAILED: %0d errors found.", error_count);
        $display("-------------------------------------------------");
        $finish;
    end

    // Task to automatically verify outputs against the behavioral reference
    task check_results;
        input [80*8:1] test_name; // String input
        begin
            if (sum !== ref_sum || cout !== ref_cout || overflow !== ref_overflow) begin
                $display("FAIL [%0s]: a=%h, b=%h, cin=%b", test_name, a, b, cin);
                $display("     Expected: sum=%h, cout=%b, ovf=%b", ref_sum, ref_cout, ref_overflow);
                $display("     Got:      sum=%h, cout=%b, ovf=%b", sum, cout, overflow);
                error_count = error_count + 1;
            end else if (test_name != "Random Pair") begin 
                // Only print passing status for the specific edge cases to keep the terminal clean
                $display("PASS [%0s]: sum=%h, cout=%b, ovf=%b", test_name, sum, cout, overflow);
            end
        end
    endtask

endmodule