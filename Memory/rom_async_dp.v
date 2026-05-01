`timescale 1ns / 1ps

module rom_async_dp (
    input wire [9:0] addr_a,
    output wire [31:0] data_a,
    input wire [9:0] addr_b,
    output wire [31:0] data_b
);
    reg [31:0] mem [0:1023];
    initial begin
        $readmemh("rom_init.mem", mem);
    end
    assign data_a = mem[addr_a];
    assign data_b = mem[addr_b];
endmodule
