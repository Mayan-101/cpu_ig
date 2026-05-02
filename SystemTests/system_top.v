/*
 * Module: system_top
 * Description: System-level integration without cache. Connects the CPU core 
 *              to ROM, RAM, and I/O peripherals using dual address decoders.
 *              Updated for Modern RISC-V Style Memory Map.
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
    wire        icache_hit = 1'b1;

    wire [31:0] dmem_addr, dmem_wr_data, dmem_rd_data;
    wire        dmem_we, dmem_re;
    wire        dcache_hit = 1'b1;

    wire irq_signal;
    wire [31:0] io_rdata_bus;
    
    //  CPU Core 
    cpu_top cpu (
        .clk(clk), .rst(rst),
        .pc(pc), .instr_in(instr_in), .icache_hit(icache_hit),
        .dmem_addr(dmem_addr), .dmem_wr_data(dmem_wr_data), .dmem_we(dmem_we), .dmem_re(dmem_re),
        .dmem_rd_data(dmem_rd_data), .dcache_ready(dcache_hit),
        .io_data_in(io_rdata_bus),
        .irq(irq_signal)
    );

    //  Data Memory Bus (MEM Stage) 
    wire rom_sel_d, ram_sel_d, io_sel_d, sys_sel_d;
    wire [15:0] rom_addr_d;
    wire [13:0] ram_addr_d;
    wire [11:0] io_addr_d;
    wire rom_we_d, ram_we_d, io_we_d;

    address_decoder data_dec (
        .addr(dmem_addr), .we(dmem_we), .re(dmem_re), .wr_data(dmem_wr_data),
        .rom_sel(rom_sel_d), .ram_sel(ram_sel_d), .io_sel(io_sel_d), .sys_ctrl_sel(sys_sel_d),
        .rom_addr(rom_addr_d), .ram_addr(ram_addr_d), .io_addr(io_addr_d), .sys_addr(),
        .rom_we(rom_we_d), .ram_we(ram_we_d), .io_we(io_we_d), .sys_ctrl_we()
    );


    //  Instruction Fetch Bus (IF Stage) 
    wire [15:0] rom_addr_i;
    
    address_decoder instr_dec (
        .addr(pc), .we(1'b0), .re(1'b1), .wr_data(32'd0),
        .rom_sel(), .ram_sel(), .io_sel(), .sys_ctrl_sel(),
        .rom_addr(rom_addr_i), .ram_addr(), .io_addr(), .sys_addr(),
        .rom_we(), .ram_we(), .io_we(), .sys_ctrl_we()
    );

    //  Memory Resources 
    wire [31:0] rom_data_instr, rom_data_load;
    rom_async_dp #(
        .ADDR_WIDTH(16),
        .DEPTH(65536)
    ) rom_inst (
        .addr_a(rom_addr_i), .data_a(rom_data_instr),
        .addr_b(rom_addr_d), .data_b(rom_data_load)
    );
    assign instr_in = rom_data_instr;

    wire [31:0] ram_rd_data;
    ram_async #(
        .ADDR_WIDTH(14),
        .DEPTH(16384)
    ) ram_inst (
        .clk(clk), .addr(ram_addr_d), .wr_data(dmem_wr_data),
        .we(ram_we_d), .rd_data(ram_rd_data),
        .addr_b(14'd0), .rd_data_b()
    );

    //  I/O Peripheral Bus 
    io_peripheral_bus io_bus (
        .clk(clk), .rst(rst),
        .io_addr(dmem_addr), .io_wdata(dmem_wr_data), .io_we(io_we_d), .io_re(dmem_re & io_sel_d), .io_size(2'b10),
        .io_rdata(io_rdata_bus), .io_ready(),
        .gpio0_pins(), .gpio1_pins(), .gpio2_pins(), .gpio3_pins(),
        .uart_tx(), .uart_rx(1'b1),
        .irq_out(irq_signal)
    );

    //  Bus Multiplexing 
    assign dmem_rd_data = ram_sel_d ? ram_rd_data : 
                          rom_sel_d ? rom_data_load : 
                          io_sel_d  ? io_rdata_bus : 32'd0;

    //  External Peripheral Ports 
    assign io_data_out = dmem_wr_data;
    assign io_addr_out = io_addr_d;
    assign io_we_out   = io_we_d;

endmodule
