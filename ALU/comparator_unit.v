`timescale 1ns / 1ps

module comparator_unit (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire        signed_mode,
    output reg         eq,
    output reg         lt,
    output reg         gt
);

    always @(*) begin
        // Equality is independent of signed/unsigned interpretation
        eq = (a == b);

        if (signed_mode) begin
            // Signed Comparison
            lt = ($signed(a) < $signed(b));
            gt = ($signed(a) > $signed(b));
        end else begin
            // Unsigned Comparison
            lt = (a < b);
            gt = (a > b);
        end
    end

endmodule