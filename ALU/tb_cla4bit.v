`timescale 1ns / 1ps

module tb_cla_4bit;

    // Inputs
    reg [3:0] a;
    reg [3:0] b;
    reg       cin;

    // Outputs
    wire [3:0] sum;
    wire       group_G;
    wire       group_P;
    wire       cout;

    // Expected values for verification
    wire [4:0] expected_sum_full; 
    assign expected_sum_full = a + b + cin;

    // Instantiate the Unit Under Test (UUT)
    cla_4bit uut (
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .group_G(group_G),
        .group_P(group_P),
        .cout(cout)
    );

    // Array to hold the 20 test vectors {cin, a, b}
    reg [8:0] test_vectors [0:19];
    integer i;

    initial begin
        // --- Populate the 20 test vectors ---
        // Vector format: {cin (1-bit), a (4-bit), b (4-bit)}
        
        // Manual Verification Case for G/P
        test_vectors[0]  = {1'b0, 4'b1100, 4'b0101}; 
        
        // Edge cases and standard checks
        test_vectors[1]  = {1'b0, 4'b0000, 4'b0000}; // All zeros
        test_vectors[2]  = {1'b1, 4'b1111, 4'b1111}; // Max values
        test_vectors[3]  = {1'b0, 4'b1010, 4'b0101}; // Alternating bits (no carry)
        test_vectors[4]  = {1'b1, 4'b1010, 4'b0101}; // Alternating bits with carry
        test_vectors[5]  = {1'b0, 4'b0001, 4'b1111}; // Ripple effect
        test_vectors[6]  = {1'b0, 4'b1111, 4'b0001}; // Ripple effect reversed
        test_vectors[7]  = {1'b1, 4'b0111, 4'b0000}; // Just passing cin
        test_vectors[8]  = {1'b0, 4'b1000, 4'b1000}; // MSB only
        test_vectors[9]  = {1'b1, 4'b0000, 4'b0000}; // Just cin
        
        // Random vectors to hit 20
        test_vectors[10] = {1'b0, 4'b0011, 4'b1100};
        test_vectors[11] = {1'b1, 4'b0110, 4'b1001};
        test_vectors[12] = {1'b0, 4'b0101, 4'b0110};
        test_vectors[13] = {1'b1, 4'b1110, 4'b0011};
        test_vectors[14] = {1'b0, 4'b1001, 4'b0111};
        test_vectors[15] = {1'b1, 4'b0010, 4'b1101};
        test_vectors[16] = {1'b0, 4'b0100, 4'b1011};
        test_vectors[17] = {1'b1, 4'b1101, 4'b0100};
        test_vectors[18] = {1'b0, 4'b1011, 4'b1110};
        test_vectors[19] = {1'b1, 4'b0111, 4'b1000};

        $display("-------------------------------------------------------------------------");
        $display(" a    | b    | c_in | sum  | c_out | grp_G | grp_P | Match?");
        $display("-------------------------------------------------------------------------");

        // Run through all vectors
        for (i = 0; i < 20; i = i + 1) begin
            {cin, a, b} = test_vectors[i];
            #10; // Wait for logic to propagate

            // Manual verification printout for Vector 0
            if (i == 0) begin
                $display("\n--- Manual Verification Case [a=1100, b=0101, cin=0] ---");
                $display("g = a & b = 0100");
                $display("p = a ^ b = 1001");
                $display("Expected grp_P = p[3]&p[2]&p[1]&p[0] = 1&0&0&1 = 0. Actual: %b", group_P);
                $display("Expected grp_G = g[3] | (p[3]&g[2]) ...  = 0 | (1&1) = 1. Actual: %b", group_G);
                $display("-------------------------------------------------------------------------");
            end

            // Check if outputs match standard addition arithmetic
            if ({cout, sum} == expected_sum_full)
                $display(" %b | %b |   %b  | %b |   %b   |   %b   |   %b   |  PASS", a, b, cin, sum, cout, group_G, group_P);
            else
                $display(" %b | %b |   %b  | %b |   %b   |   %b   |   %b   |  FAIL!", a, b, cin, sum, cout, group_G, group_P);
        end

        $display("-------------------------------------------------------------------------");
        $display("Testing complete.");
        $finish;
    end

endmodule