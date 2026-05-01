`timescale 1ns / 1ps

module tb_full_adder;

    // Inputs
    reg a;
    reg b;
    reg cin;

    // Outputs
    wire sum;
    wire cout;

    // Loop variable
    integer i;

    // Instantiate the Unit Under Test (UUT)
    full_adder uut (
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .cout(cout)
    );

    initial begin
        // Setup monitoring to display the truth table format
        $display("------------------------------------------");
        $display(" Time  | a | b | cin | sum | cout ");
        $display("------------------------------------------");
        $monitor(" %5t | %b | %b |  %b  |  %b  |  %b   ", $time, a, b, cin, sum, cout);

        // Exhaustive test: Loop through 0 to 7 to cover all 3-bit combinations
        for (i = 0; i < 8; i = i + 1) begin
            // Concatenate inputs and assign the loop index
            {a, b, cin} = i; 
            #10; 
        end

        // End simulation
        $display("------------------------------------------");
        $display("Exhaustive testing complete.");
        $finish;
    end

endmodule