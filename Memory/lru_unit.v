`timescale 1ns / 1ps

module lru_unit (
    input  wire clk,
    input  wire rst,
    input  wire [1:0] access_way,
    input  wire update_en,
    output reg  [1:0] lru_way
);

    reg [1:0] age [0:3];

    always @(*) begin
        if (age[0] == 2'b00) lru_way = 2'd0;
        else if (age[1] == 2'b00) lru_way = 2'd1;
        else if (age[2] == 2'b00) lru_way = 2'd2;
        else lru_way = 2'd3;
    end

    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 4; i = i + 1) begin
                age[i] <= 2'b00;
            end
        end else if (update_en) begin
            for (i = 0; i < 4; i = i + 1) begin
                if (i == access_way) begin
                    age[i] <= 2'b11;
                end else begin
                    if (age[i] > age[access_way]) begin
                        age[i] <= age[i] - 1'b1;
                    end
                end
            end
        end
    end

endmodule
