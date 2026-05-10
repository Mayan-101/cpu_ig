`timescale 1ns / 1ps

module lru_unit #(
    parameter WAYS = 4
)(
    input  wire clk,
    input  wire rst,
    input  wire [$clog2(WAYS)-1:0] access_way,
    input  wire update_en,
    output reg  [$clog2(WAYS)-1:0] lru_way
);

    reg [$clog2(WAYS)-1:0] age [0:WAYS-1];

    always @(*) begin
        lru_way = 0;
        begin : find_lru
            integer k;
            for (k = 0; k < WAYS; k = k + 1) begin
                if (age[k] == 0) begin
                    lru_way = k[$clog2(WAYS)-1:0];
                    disable find_lru;
                end
            end
        end
    end

    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < WAYS; i = i + 1) begin
                age[i] <= i[$clog2(WAYS)-1:0]; // Initialize with unique ages
            end
        end else if (update_en) begin
            for (i = 0; i < WAYS; i = i + 1) begin
                if (i == access_way) begin
                    age[i] <= WAYS[$clog2(WAYS)-1:0] - 1'b1;
                end else begin
                    if (age[i] > age[access_way]) begin
                        age[i] <= age[i] - 1'b1;
                    end
                end
            end
        end
    end

endmodule

