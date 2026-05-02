`timescale 1ns / 1ps

module tb_float_ftoi;
    reg [31:0] float_in;
    wire [31:0] int_out;

    float_ftoi uut (
        .float_in(float_in),
        .int_out(int_out)
    );

    task test_ftoi(input [31:0] val);
        begin
            float_in = val;
            #10;
            $display("FLOAT: 0x%h -> INT: %d (0x%h)", val, $signed(int_out), int_out);
        end
    endtask

    initial begin
        $display("Starting FTOI unit tests...");
        
        // Basic Cases
        test_ftoi(32'h00000000); // 0.0
        test_ftoi(32'h3f800000); // 1.0
        test_ftoi(32'hbf800000); // -1.0
        test_ftoi(32'h41200000); // 10.0
        test_ftoi(32'hc1200000); // -10.0

        // Fractional Cases (Truncation)
        test_ftoi(32'h3fc00000); // 1.5 -> 1
        test_ftoi(32'hbfc00000); // -1.5 -> -1
        test_ftoi(32'h40100000); // 2.25 -> 2

        // Underflow
        test_ftoi(32'h3f000000); // 0.5 -> 0

        // Large Numbers
        test_ftoi(32'h49742400); // 1,000,000
        test_ftoi(32'h4effffff); // 2,147,483,647 (Max Int)
        test_ftoi(32'hcf000000); // -2,147,483,648 (Min Int)

        // Infinity / NaN
        test_ftoi(32'h7f800000); // +Inf
        test_ftoi(32'hff800000); // -Inf
        test_ftoi(32'h7fc00000); // NaN

        $display("Unit tests complete.");
        $finish;
    end
endmodule
