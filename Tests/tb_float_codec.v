`timescale 1ns / 1ps

module tb_float_codec;

    reg [31:0] test_input;
    wire s;
    wire [7:0] e;
    wire [22:0] m;
    wire z, inf, nan, den;
    wire [31:0] test_output;

    // Instantiate Unpacker
    float_unpacker unpacker (
        .float32(test_input),
        .sign(s), .exponent(e), .mantissa(m),
        .is_zero(z), .is_inf(inf), .is_nan(nan), .is_denormal(den)
    );

    // Instantiate Packer
    float_packer packer (
        .sign(s), .exponent(e), .mantissa(m),
        .float32(test_output)
    );

    initial begin
        $display("Starting IEEE 754 Codec Tests...");
        $display("------------------------------------------------------------------");
        $display(" Case         | Input Hex | S | Exp | Mantissa | Z|I|N|D | Match?");
        $display("------------------------------------------------------------------");

        // 1. Zero (0.0)
        run_test(32'h00000000, "0.0         ");
        
        // 2. Positive One (1.0)
        run_test(32'h3F800000, "1.0         ");
        
        // 3. Negative One (-1.0)
        run_test(32'hBF800000, "-1.0        ");
        
        // 4. Infinity (+INF)
        run_test(32'h7F800000, "+INF        ");
        
        // 5. NaN
        run_test(32'h7FC00000, "NaN         ");
        
        // 6. Smallest Denormal
        run_test(32'h00000001, "Denormal    ");

        $display("------------------------------------------------------------------");
        $finish;
    end

    task run_test(input [31:0] val, input [12*8:1] label);
        begin
            test_input = val;
            #10;
            $display(" %s | %h  | %b | %h  | %h   | %b|%b|%b|%b | %s", 
                     label, test_input, s, e, m, z, inf, nan, den,
                     (test_input === test_output ? "PASS" : "FAIL"));
        end
    endtask

endmodule
