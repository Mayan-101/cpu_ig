`timescale 1ns / 1ps

module address_decoder (
    input wire [31:0] addr,
    input wire we,
    input wire re,
    input wire [31:0] wr_data,
    
    output wire rom_sel,
    output wire ram_sel,
    output wire io_sel,
    output wire sys_ctrl_sel,
    
    // Extracted local addresses (word-aligned)
    output wire [15:0] rom_addr, // 256 KB = 65536 words
    output wire [13:0] ram_addr, // 64 KB = 16384 words
    output wire [11:0] io_addr,  // 4 KB peripheral space
    output wire [11:0] sys_addr, // 4 KB system control space
    
    // Masked write enables
    output wire rom_we,
    output wire ram_we,
    output wire io_we,
    output wire sys_ctrl_we
);

    // Modern RISC-V Style Memory Map:
    // ROM:        0x0000_0000 - 0x0003_FFFF
    // RAM:        0x2000_0000 - 0x2000_FFFF
    // Peripheral: 0x4000_0000 - 0x4000_0FFF
    // System:     0x8000_0000 - 0x8000_0FFF
    
    assign rom_sel      = (addr >= 32'h0000_0000 && addr <= 32'h0003_FFFF);
    assign ram_sel      = (addr >= 32'h2000_0000 && addr <= 32'h2000_FFFF);
    assign io_sel       = (addr >= 32'h4000_0000 && addr <= 32'h4000_0FFF);
    assign sys_ctrl_sel = (addr >= 32'h8000_0000 && addr <= 32'h8000_0FFF);
    
    // Local address extraction
    assign rom_addr = addr[17:2];
    assign ram_addr = addr[15:2];
    assign io_addr  = addr[11:0];
    assign sys_addr = addr[11:0];
    
    // Write enables
    assign rom_we       = 1'b0; 
    assign ram_we       = we & ram_sel;
    assign io_we        = we & io_sel;
    assign sys_ctrl_we  = we & sys_ctrl_sel;

endmodule
