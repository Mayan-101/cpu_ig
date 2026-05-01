/*
 * Module: system_cache_top
 * Description: System-level integration with L1 Caches. Implements a Harvard 
 *              architecture with separate I-Cache and D-Cache, managed by a simple 
 *              memory arbiter with emulated wait states.
 */
module system_cache_top (
    input  wire        clk,
    input  wire        rst,
    output wire [31:0] io_data_out,
    output wire [15:0] io_addr_out,
    output wire        io_we_out,
    output wire        stall_cpu 
);

    //  Core Pipeline Interconnects 
    wire [31:0] pc, instr_in;
    wire        icache_ready;
    wire [31:0] dmem_addr, dmem_wr_data, dmem_rd_data;
    wire        dmem_we, dmem_re;
    wire        dcache_ready;

    cpu_top cpu (
        .clk(clk), .rst(rst),
        .pc(pc), .instr_in(instr_in), .icache_hit(icache_ready),
        .dmem_addr(dmem_addr), .dmem_wr_data(dmem_wr_data), .dmem_we(dmem_we), .dmem_re(dmem_re),
        .dmem_rd_data(dmem_rd_data), .dcache_ready(dcache_ready),
        .io_data_in(32'd0)
    );

    //  L1 Cache Subsystem 
    wire [63:0] mem_rd_data;
    wire        mem_ready;
    wire [31:0] ic_rd_data;
    wire        ic_hit, ic_stall, dc_stall;
    wire [31:0] mem_addr_i, mem_addr_d;
    wire        mem_req_i, mem_req_d;
    wire        mem_we_d;
    wire [31:0] mem_wr_data_d;
    
    // Instruction Cache (L1I)
    l1_cache icache (
        .clk(clk), .reset(rst),
        .addr(pc), .wr_data(32'd0), .we(1'b0), .re(1'b1),
        .rd_data(ic_rd_data), .hit(ic_hit), .stall(ic_stall),
        .mem_data(mem_rd_data), .mem_ready(mem_ready && mem_req_i),
        .mem_req(mem_req_i), .mem_addr(mem_addr_i), .mem_we(), .mem_wr_data()
    );
    assign instr_in = ic_rd_data;
    assign icache_ready = !ic_stall;

    // Data Cache (L1D)
    l1_cache dcache (
        .clk(clk), .reset(rst),
        .addr(dmem_addr), .wr_data(dmem_wr_data), .we(dmem_we), .re(dmem_re),
        .rd_data(dmem_rd_data), .hit(), .stall(dc_stall),
        .mem_data(mem_rd_data), .mem_ready(mem_ready && mem_req_d),
        .mem_req(mem_req_d), .mem_addr(mem_addr_d), .mem_we(mem_we_d), .mem_wr_data(mem_wr_data_d)
    );
    assign dcache_ready = !dc_stall;
    assign stall_cpu    = ic_stall || dc_stall;

    //  Memory Arbitration 
    // Simple priority arbiter: Data cache requests take precedence over instruction fetches.
    wire [31:0] active_mem_addr = mem_req_d ? mem_addr_d : mem_addr_i;
    wire        active_mem_we   = mem_req_d ? mem_we_d : 1'b0;
    wire        active_mem_req  = mem_req_i || mem_req_d;
    
    //  Physical Memory Resources 
    wire [31:0] rom_data, ram_data;
    rom_async_dp main_rom (
        .addr_a(active_mem_addr[11:2]), .data_a(rom_data),
        .addr_b(active_mem_addr[11:2] + 10'd1), .data_b() 
    );

    ram_async main_ram (
        .clk(clk), .addr(active_mem_addr[6:2]), .wr_data(mem_wr_data_d), .we(active_mem_we),
        .rd_data(ram_data)
    );

    assign mem_rd_data = (active_mem_addr < 32'h1000) ? {32'd0, rom_data} : {32'd0, ram_data};
    
    //  Memory Latency Emulation 
    // Emulates a 2-cycle access latency for main memory.
    reg [1:0] mem_wait;
    always @(posedge clk) begin
        if (rst) mem_wait <= 0;
        else if (active_mem_req && mem_wait < 2) mem_wait <= mem_wait + 1;
        else if (!active_mem_req) mem_wait <= 0;
    end
    assign mem_ready = (mem_wait == 2);

endmodule
