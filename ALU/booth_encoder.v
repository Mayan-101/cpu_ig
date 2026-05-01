`timescale 1ns / 1ps

module booth_encoder (
    input  wire [2:0] window,
    // pp_select: [2] = sign (1=neg), [1] = magnitude (1=non-zero), [0] = double (1=2x)
    output reg  [2:0] pp_select 
);

    always @(*) begin
        case(window)
            3'b000: pp_select = 3'b000; // 0
            3'b001: pp_select = 3'b010; // +1
            3'b010: pp_select = 3'b010; // +1
            3'b011: pp_select = 3'b011; // +2
            3'b100: pp_select = 3'b111; // -2
            3'b101: pp_select = 3'b110; // -1
            3'b110: pp_select = 3'b110; // -1
            3'b111: pp_select = 3'b000; // 0
        endcase
    end

endmodule
