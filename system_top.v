/*
 * Module: system_top
 * Description: System-level integration without cache. Connects the CPU core 
 *              to ROM, RAM, and I/O peripherals using dual address decoders.
 */
module system_top (
    input  wire        clk,
    input  wire        rst,
    output wire [31:0] io_data_out,
    output wire [15:0] io_addr_out,
    output wire        io_we_out
);

    //  Internal Bus Interconnects 
    wire [31:0] pc, instr_in;
    wire        icache_hit = 1'b1; // Direct fetch without I-cache latency

    wire [31:0] dmem_addr, dmem_wr_data, dmem_rd_data;
    wire        dmem_we, dmem_re;
    wire        dcache_hit = 1'b1; // Direct access without D-cache latency

    //  CPU Core 
    cpu_top cpu (
        .clk(clk), .rst(rst),
        .pc(pc), .instr_in(instr_in), .icache_hit(icache_hit),
        .dmem_addr(dmem_addr), .dmem_wr_data(dmem_wr_data), .dmem_we(dmem_we), .dmem_re(dmem_re),
        .dmem_rd_data(dmem_rd_data), .dcache_ready(dcache_hit),
        .io_data_in(32'd0)
    );

    //  Data Memory Bus (MEM Stage) 
    wire rom_sel_d, ram_sel_d, io_sel_d;
    wire [9:0] rom_addr_d;
    wire [4:0] ram_addr_d;
    wire [15:0] io_addr_d;
    wire rom_we_d, ram_we_d, io_we_d;

    address_decoder data_dec (
        .addr(dmem_addr), .we(dmem_we), .re(dmem_re), .wr_data(dmem_wr_data),
        .rom_sel(rom_sel_d), .ram_sel(ram_sel_d), .io_sel(io_sel_d),
        .rom_addr(rom_addr_d), .ram_addr(ram_addr_d), .io_addr(io_addr_d),
        .rom_we(rom_we_d), .ram_we(ram_we_d), .io_we(io_we_d)
    );

    //  Instruction Fetch Bus (IF Stage) 
    wire rom_sel_i, ram_sel_i, io_sel_i;
    wire [9:0] rom_addr_i;
    wire [4:0] ram_addr_i;
    wire [15:0] io_addr_i;
    
    address_decoder instr_dec (
        .addr(pc), .we(1'b0), .re(1'b1), .wr_data(32'd0),
        .rom_sel(rom_sel_i), .ram_sel(ram_sel_i), .io_sel(io_sel_i),
        .rom_addr(rom_addr_i), .ram_addr(ram_addr_i), .io_addr(io_addr_i),
        .rom_we(), .ram_we(), .io_we()
    );

    //  Memory Resources 
    wire [31:0] rom_data_instr, rom_data_load;
    rom_async_dp rom_inst (
        .addr_a(rom_addr_i), .data_a(rom_data_instr),
        .addr_b(rom_addr_d), .data_b(rom_data_load)
    );
    assign instr_in = rom_data_instr;

    wire [31:0] ram_rd_data;
    ram_async ram_inst (
        .clk(clk), .addr(ram_addr_d), .wr_data(dmem_wr_data),
        .we(ram_we_d), .rd_data(ram_rd_data)
    );

    //  Bus Multiplexing 
    assign dmem_rd_data = ram_sel_d ? ram_rd_data : 
                          rom_sel_d ? rom_data_load : 32'd0;

    //  External Peripheral Ports 
    assign io_data_out = dmem_wr_data;
    assign io_addr_out = io_addr_d;
    assign io_we_out   = io_we_d;

endmodule
