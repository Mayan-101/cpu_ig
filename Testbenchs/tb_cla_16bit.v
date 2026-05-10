`timescale 1ns / 1ps

module tb_cla_16bit;
    reg [15:0] a, b;
    reg cin;
    wire [15:0] sum;
    wire cout, overflow;

    // Reference model
    wire [16:0] ref_res = a + b + cin;
    wire ref_ovf = (a[15] == b[15]) && (sum[15] != a[15]);

    cla_16bit uut (a, b, cin, sum, , , cout, overflow);

    integer i, errors = 0;

    initial begin
        $display("Starting 16-bit CLA Verification...");

        // Case 1: 0x0000 + 0x0000
        a = 16'h0000; b = 16'h0000; cin = 0; #10;
        check("Zero Add");

        // Case 2: 0xFFFF + 0x0001 (Unsigned Wrap, No Signed Overflow)
        a = 16'hFFFF; b = 16'h0001; cin = 0; #10;
        check("Unsigned Wrap");

        // Case 3: 0x7FFF + 0x0001 (Signed Overflow)
        a = 16'h7FFF; b = 16'h0001; cin = 0; #10;
        check("Signed Overflow");

        // Case 4: 50 Random Pairs
        for (i = 0; i < 50; i = i + 1) begin
            a = $random; b = $random; cin = $random % 2; #10;
            if (sum !== ref_res[15:0] || cout !== ref_res[16] || overflow !== ref_ovf) begin
                $display("FAIL: a=%h b=%h cin=%b | Got sum=%h cout=%b ovf=%b", a, b, cin, sum, cout, overflow);
                errors = errors + 1;
            end
        end

        $display("Tests Finished. Errors: %0d", errors);
        $finish;
    end

    task check(input [127:0] name);
        if (sum === ref_res[15:0] && cout === ref_res[16] && overflow === ref_ovf)
            $display("PASS [%0s]: sum=%h cout=%b ovf=%b", name, sum, cout, overflow);
        else begin
            $display("FAIL [%0s]: a=%h b=%h | Expected sum=%h cout=%b ovf=%b", name, a, b, ref_res[15:0], ref_res[16], ref_ovf);
            errors = errors + 1;
        end
    endtask
endmodule
