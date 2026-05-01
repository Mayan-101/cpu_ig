`timescale 1ns / 1ps

module booth_multiplier (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire [31:0] a, // Multiplicand
    input  wire [31:0] b, // Multiplier
    output reg  [63:0] product,
    output reg         done
);

    reg [64:0] acc;
    reg [31:0] mcand;
    reg [4:0]  step_count;
    reg [1:0]  state;

    localparam IDLE = 2'b00, COMPUTE = 2'b01, DONE = 2'b10;

    wire [2:0] b_code;
    wire [64:0] next_acc;

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
                        acc <= {32'b0, b, 1'b0};
                        mcand <= a;
                        step_count <= 0;
                        state <= COMPUTE;
                    end
                end
                COMPUTE: begin
                    acc <= next_acc;
                    if (step_count == 15) state <= DONE;
                    else step_count <= step_count + 1;
                end
                DONE: begin
                    done <= 1;
                    product <= acc[64:1];
                    if (!start) state <= IDLE; // Wait for handshake release
                end
            endcase
        end
    end
endmodule
