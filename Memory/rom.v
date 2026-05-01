`timescale 1ns / 1ps

module rom (
    input wire clk,
    input wire [9:0] addr, // 10-bit address for 1024 words
    input wire rd_en,
    output reg [31:0] data,
    output reg valid
);

    // 1024 words x 32 bits (4 KB)
    reg [31:0] mem [0:1023];

    // Load initial contents at elaboration
    initial begin
        $readmemh("rom_init.mem", mem);
    end

    // Synchronous read
    always @(posedge clk) begin
        if (rd_en) begin
            data <= mem[addr];
            valid <= 1'b1;
        end else begin
            valid <= 1'b0;
        end
    end

endmodule
