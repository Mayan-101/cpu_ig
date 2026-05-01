`timescale 1ns / 1ps

module address_decoder (
    input wire [31:0] addr,
    input wire we,
    input wire re,
    input wire [31:0] wr_data,
    
    output wire rom_sel,
    output wire ram_sel,
    output wire io_sel,
    
    // Extracted local addresses (word-aligned)
    output wire [9:0] rom_addr, // 4 KB = 1024 words
    output wire [4:0] ram_addr, // 128 B = 32 words
    output wire [15:0] io_addr, // 16-bit I/O space
    
    // Masked write enables
    output wire rom_we,
    output wire ram_we,
    output wire io_we
);

    // Memory Map:
    // ROM: 0x0000_0000 - 0x0000_0FFF
    // RAM: 0x0000_1000 - 0x0000_107F
    // I/O: >= 0x0000_1080
    
    assign rom_sel = (addr < 32'h0000_1000);
    assign ram_sel = (addr >= 32'h0000_1000 && addr < 32'h0000_1080);
    assign io_sel  = (addr >= 32'h0000_1080);
    
    // Address extraction (dropping the lowest 2 bits for word alignment)
    // ROM: 4KB / 4 = 1024 words -> 10 bits
    assign rom_addr = addr[11:2];
    
    // RAM: 128B / 4 = 32 words -> 5 bits
    assign ram_addr = addr[6:2];
    
    // I/O: Keep as a byte/port address or word aligned. 
    // Assuming I/O instructions specify 16-bit port directly.
    assign io_addr = addr[15:0];
    
    // Write enables
    // ROM write attempt -> we is NOT forwarded to ROM.
    assign rom_we = 1'b0; 
    assign ram_we = we & ram_sel;
    assign io_we  = we & io_sel;

endmodule
