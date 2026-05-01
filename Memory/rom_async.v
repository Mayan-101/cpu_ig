`timescale 1ns / 1ps

module rom_async (
    input wire [9:0] addr,
    output wire [31:0] data
);
    reg [31:0] mem [0:1023];
    initial begin
        $readmemh("rom_init.mem", mem);
    end
    assign data = mem[addr];
endmodule
