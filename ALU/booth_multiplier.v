`timescale 1ns / 1ps

module booth_multiplier (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire [31:0] a, // Multiplicand
    input  wire [31:0] b, // Multiplier
    input  wire a_signed,
    input  wire b_signed,
    output reg  [63:0] product,
    output reg         done
);

    reg [68:0] acc; // Increased for 34-bit Booth (extended for sign/zero)
    reg [33:0] mcand;
    reg [5:0]  step_count;
    reg [1:0]  state;


    localparam IDLE = 2'b00, COMPUTE = 2'b01, DONE = 2'b10;

    wire [2:0] b_code;
    wire [68:0] next_acc;


    booth_encoder enc (.window(acc[2:0]), .pp_select(b_code));
    booth_step    step_logic (.acc(acc), .multiplicand(mcand), .booth_code(b_code), .new_acc(next_acc));

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            done <= 0;
            product <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        // Extend operands to 34 bits
                        // If signed, sign-extend; if unsigned, zero-extend.
                        acc <= {34'b0, (b_signed ? { {2{b[31]}}, b } : { 2'b0, b }), 1'b0};
                        mcand <= a_signed ? { {2{a[31]}}, a } : { 2'b0, a };
                        step_count <= 0;
                        state <= COMPUTE;
                    end
                end
                COMPUTE: begin
                    acc <= next_acc;
                    if (step_count == 16) state <= DONE; // 17 steps for 34 bits (Radix-4)
                    else step_count <= step_count + 1;
                end
                DONE: begin
                    done <= 1;
                    product <= acc[64:1]; // Result is in the lower 64 bits of the shifted acc
                    if (!start) state <= IDLE; // Wait for handshake release
                end
            endcase
        end
    end

endmodule
