`timescale 1ns / 1ps

module tb_float_itof;
    reg [31:0] int_in;
    wire [31:0] float_out;

    float_itof uut (
        .int_in(int_in),
        .float_out(float_out)
    );

    task test_itof(input signed [31:0] val);
        begin
            int_in = val;
            #10;
            $display("INT: %d (0x%h) -> FLOAT: 0x%h", val, val, float_out);
        end
    endtask

    initial begin
        $display("Starting ITOF unit tests...");
        
        // Basic Cases
        test_itof(0);
        test_itof(1);
        test_itof(-1);
        test_itof(2);
        test_itof(-2);
        test_itof(10);
        test_itof(-10);

        // Larger Numbers
        test_itof(1024);
        test_itof(1000000);
        test_itof(-1000000);

        // Edge Cases: INT_MAX, INT_MIN
        test_itof(2147483647); // 0x7FFFFFFF
        test_itof(-2147483648); // 0x80000000

        // Random large value
        test_itof(12345678);

        $display("Unit tests complete.");
        $finish;
    end
endmodule
