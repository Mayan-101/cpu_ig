`timescale 1ns / 1ps

module tb_booth_encoder;
    reg [2:0] window;
    wire [2:0] pp;
    integer i;

    booth_encoder uut (window, pp);

    initial begin
        $display("M4.1 Booth Encoder Tests");
        $display(" In  | Sign | Mag | Double | Action");
        $display("-----------------------------------");
        for (i = 0; i < 8; i = i + 1) begin
            window = i; #5;
            $write(" %b |  %b   |  %b  |   %b    | ", window, pp[2], pp[1], pp[0]);
            case(pp)
                3'b000: $display(" 0");
                3'b010: $display("+1x");
                3'b011: $display("+2x");
                3'b110: $display("-1x");
                3'b111: $display("-2x");
            endcase
        end
        $finish;
    end
endmodule
