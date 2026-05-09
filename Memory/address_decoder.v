`timescale 1ns / 1ps

module address_decoder (
    input wire [31:0] addr,
    input wire we,
    input wire re,
    input wire [31:0] wr_data,
    
    output wire itcm_sel,
    output wire dtcm_sel,
    output wire ram_sel,
    output wire io_sel,
    output wire sys_ctrl_sel,
    
    // Extracted local addresses (word-aligned)
    output wire [13:0] itcm_addr, // 64 KB = 16384 words
    output wire [13:0] dtcm_addr, // 64 KB
    output wire [21:0] ram_addr,  // 16 MB = 4194304 words
    output wire [11:0] io_addr,   // 4 KB peripheral space
    output wire [11:0] sys_addr,  // 4 KB system control space
    
    // Masked write enables
    output wire itcm_we,
    output wire dtcm_we,
    output wire ram_we,
    output wire io_we,
    output wire sys_ctrl_we
);

    // New Memory Map (MemoryMap.md):
    // ITCM:        0x0000_0000 - 0x0000_FFFF (64 KB)
    // DTCM:        0x0001_0000 - 0x0001_FFFF (64 KB)
    // Main RAM:    0x1000_0000 - 0x10FF_FFFF (16 MB)
    // Peripheral:  0x4000_0000 - 0x4FFF_FFFF (256 MB)
    // System/CSR:  0x8000_0000 - 0x8000_0FFF (4 KB)
    
    assign itcm_sel     = (addr >= 32'h0000_0000 && addr <= 32'h0000_FFFF);
    assign dtcm_sel     = (addr >= 32'h0001_0000 && addr <= 32'h0001_FFFF);
    assign ram_sel      = (addr >= 32'h1000_0000 && addr <= 32'h10FF_FFFF);
    assign io_sel       = (addr >= 32'h4000_0000 && addr <= 32'h4FFF_FFFF);
    assign sys_ctrl_sel = (addr >= 32'h8000_0000 && addr <= 32'h8000_0FFF);
    
    // Local address extraction
    assign itcm_addr = addr[15:2]; // 64 KB
    assign dtcm_addr = addr[15:2]; // 64 KB
    assign ram_addr  = addr[23:2]; // 16 MB (word-aligned)
    assign io_addr   = addr[11:0];
    assign sys_addr  = addr[11:0];
    
    // Write enables
    assign itcm_we      = we & itcm_sel; 
    assign dtcm_we      = we & dtcm_sel;
    assign ram_we       = we & ram_sel;
    assign io_we        = we & io_sel;
    assign sys_ctrl_we  = we & sys_ctrl_sel;

endmodule
