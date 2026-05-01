`timescale 1ns / 1ps

module bus_arbiter (
    input wire if_req,
    input wire [31:0] if_addr,
    
    input wire mem_req,
    input wire [31:0] mem_addr,
    input wire mem_we,
    input wire [31:0] mem_data,
    
    output wire [31:0] bus_addr,
    output wire bus_we,
    output wire [31:0] bus_wr_data,
    
    output wire if_stall,
    output wire grant // 0=IF, 1=MEM
);

    // Contention resolution: MEM wins, IF stalls
    assign grant = mem_req;
    
    // IF is stalled only if it is requesting while MEM is also requesting
    assign if_stall = if_req & mem_req;

    // Bus multiplexing
    assign bus_addr = mem_req ? mem_addr : if_addr;
    
    // Instruction Fetch never writes
    assign bus_we = mem_req ? mem_we : 1'b0;
    assign bus_wr_data = mem_req ? mem_data : 32'd0;

endmodule
