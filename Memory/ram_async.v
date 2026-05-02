`timescale 1ns / 1ps

module ram_async #(
    parameter ADDR_WIDTH = 14,
    parameter DEPTH = 16384
)(
    input wire clk,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [31:0] wr_data,
    input wire we,
    output wire [31:0] rd_data,
    
    // Optional second read port for cache refill
    input wire [ADDR_WIDTH-1:0] addr_b,
    output wire [31:0] rd_data_b
);

    reg [31:0] mem [0:DEPTH-1];
    
    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1) mem[i] = 32'd0;
        $readmemh("ram_init.mem", mem);
    end

    always @(posedge clk) begin
        if (we) begin
            mem[addr] <= wr_data;
        end
    end

    assign rd_data = mem[addr];
    assign rd_data_b = mem[addr_b];

endmodule
