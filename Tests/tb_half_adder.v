`timescale 1ns / 1ps

module tb_half_adder;

    // Inputs
    reg a;
    reg b;

    // Outputs
    wire sum;
    wire cout;

    // Instantiate the Unit Under Test (UUT)
    half_adder uut (
        .a(a),
        .b(b),
        .sum(sum),
        .cout(cout)
    );

    initial begin
        // Setup monitoring to automatically print when signals change
        $display("-----------------------------------");
        $display(" Time  | a | b | sum | cout ");
        $display("-----------------------------------");
        $monitor(" %5t | %b | %b |  %b  |  %b  ", $time, a, b, sum, cout);

        // Test Case 1: a=0, b=0 (Expected: sum=0, cout=0)
        a = 0; b = 0;
        #10; 

        // Test Case 2: a=0, b=1 (Expected: sum=1, cout=0)
        a = 0; b = 1;
        #10; 

        // Test Case 3: a=1, b=0 (Expected: sum=1, cout=0)
        a = 1; b = 0;
        #10; 

        // Test Case 4: a=1, b=1 (Expected: sum=0, cout=1)
        a = 1; b = 1;
        #10; 

        // End simulation
        $display("-----------------------------------");
        $display("Exhaustive testing complete.");
        $finish;
    end

endmodule