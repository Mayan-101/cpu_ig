`timescale 1ns / 1ps

module barrel_shifter (
    input  wire [31:0] a,
    input  wire [4:0]  shamt,      // 5-bit shift amount for 32-bit range
    input  wire [1:0]  shift_type, // 00: LSL, 01: LSR, 10: ASR, 11: ROR
    output reg  [31:0] result,
    output reg         carry_out   // The last bit shifted out
);

    always @(*) begin
        if (shamt == 5'b0) begin
            result = a;
            carry_out = 1'b0;
        end else begin
            case (shift_type)
                2'b00: begin // LSL: Logical Shift Left
                    result = a << shamt;
                    carry_out = a[32 - shamt];
                end
                2'b01: begin // LSR: Logical Shift Right
                    result = a >> shamt;
                    carry_out = a[shamt - 1];
                end
                2'b10: begin // ASR: Arithmetic Shift Right
                    result = $signed(a) >>> shamt;
                    carry_out = a[shamt - 1];
                end
                default: begin
                    result = a;
                    carry_out = 1'b0;
                end
            endcase

        end
    end

endmodule
