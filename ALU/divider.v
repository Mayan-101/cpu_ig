`timescale 1ns / 1ps

module divider (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire [31:0] dividend,
    input  wire [31:0] divisor,
    output reg  [31:0] quotient,
    output reg  [31:0] remainder,
    output reg         done,
    output reg         div_zero
);

    reg [31:0] M;
    reg [63:0] AQ;
    reg [5:0]  step;
    reg [1:0]  state;
    reg [63:0] shifted_AQ;

    localparam IDLE = 2'b00, DIVIDING = 2'b01, FINISH = 2'b10;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            done <= 0; div_zero <= 0;
            quotient <= 0; remainder <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        if (divisor == 0) begin
                            div_zero <= 1; done <= 1;
                        end else begin
                            div_zero <= 0;
                            M <= divisor;
                            AQ <= {32'b0, dividend};
                            step <= 0;
                            state <= DIVIDING;
                        end
                    end
                end

                DIVIDING: begin
                    // 1. Shift AQ left by 1
                    shifted_AQ = AQ << 1;

                    // 2. Add or Sub based on previous A sign
                    if (AQ[63] == 1'b0) begin
                        shifted_AQ[63:32] = shifted_AQ[63:32] - M;
                    end else begin
                        shifted_AQ[63:32] = shifted_AQ[63:32] + M;
                    end

                    // 3. Set Quotient bit
                    shifted_AQ[0] = ~shifted_AQ[63];

                    AQ <= shifted_AQ;

                    if (step == 31) state <= FINISH;
                    else step <= step + 1;
                end

                FINISH: begin
                    // Final restore if remainder is negative
                    if (AQ[63] == 1'b1)
                        remainder <= AQ[63:32] + M;
                    else
                        remainder <= AQ[63:32];
                    quotient <= AQ[31:0];
                    done <= 1;
                    if (!start) state <= IDLE;
                end
            endcase
        end
    end
endmodule
