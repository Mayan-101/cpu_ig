`timescale 1ns / 1ps

module tb_sub_32bit;

    reg [31:0] a, b;
    wire [31:0] diff;
    wire borrow, overflow;

    // Reference for comparison
    wire [31:0] ref_diff = a - b;
    wire ref_borrow = (a < b);
    wire ref_ovf = (a[31] != b[31]) && (diff[31] != a[31]);

    sub_32bit uut (
        .a(a), .b(b),
        .diff(diff), .borrow(borrow), .overflow(overflow)
    );

    integer i, errors = 0;

    initial begin
        $display("Starting 32-bit Subtractor Tests...");

        // Case 1: 5 - 3 = 2
        a = 32'd5; b = 32'd3; #10;
        check("5 - 3");

        // Case 2: 0 - 1 (Borrow Expected)
        a = 32'd0; b = 32'd1; #10;
        check("0 - 1");

        // Case 3: MIN_INT - 1 (Overflow Expected)
        // 0x80000000 - 0x00000001 = 0x7FFFFFFF (wraps to positive)
        a = 32'h80000000; b = 32'h00000001; #10;
        check("MIN_INT - 1");

        // Case 4: 50 Random Pairs
        for (i = 0; i < 50; i = i + 1) begin
            a = $random; b = $random; #10;
            if (diff !== ref_diff || borrow !== ref_borrow || overflow !== ref_ovf) begin
                $display("FAIL: a=%h b=%h | Got diff=%h brw=%b ovf=%b", a, b, diff, borrow, overflow);
                errors = errors + 1;
            end
        end

        $display("\n-------------------------------------------------");
        if (errors == 0) $display("SUCCESS: Subtractor logic is correct!");
        else $display("FAILURE: %0d errors found.", errors);
        $display("-------------------------------------------------");
        $finish;
    end

    task check(input [128:0] name);
        if (diff === ref_diff && borrow === ref_borrow && overflow === ref_ovf)
            $display("PASS [%0s]: diff=%h borrow=%b ovf=%b", name, diff, borrow, overflow);
        else begin
            $display("FAIL [%0s]: a=%h b=%h | Expected diff=%h borrow=%b ovf=%b", 
                     name, a, b, ref_diff, ref_borrow, ref_ovf);
            errors = errors + 1;
        end
    endtask

endmodule
