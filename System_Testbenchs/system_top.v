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
        .ibus_addr(pc), .ibus_rdata(instr_in), .ibus_ready(icache_hit),
        .dbus_addr(dmem_addr), .dbus_wdata(dmem_wr_data), .dbus_we(dmem_we), .dbus_re(dmem_re),
        .dbus_rdata(dmem_rd_data), .dbus_ready(dcache_hit),
        .dbus_io_rdata(io_rdata_bus),
        .irq(irq_signal)
    );


    //  Data Memory Bus (MEM Stage) 
    wire itcm_sel_d, dtcm_sel_d, ram_sel_d, io_sel_d, sys_sel_d;
    wire [11:0] itcm_addr_d;
    wire [10:0] dtcm_addr_d;
    wire [22:0] ram_addr_d;
    wire [11:0] io_addr_d;
    wire itcm_we_d, dtcm_we_d, ram_we_d, io_we_d;

    address_decoder data_dec (
        .addr(dmem_addr), .we(dmem_we), .re(dmem_re), .wr_data(dmem_wr_data),
        .itcm_sel(itcm_sel_d), .dtcm_sel(dtcm_sel_d), .ram_sel(ram_sel_d), .io_sel(io_sel_d), .sys_ctrl_sel(sys_sel_d),
        .itcm_addr(itcm_addr_d), .dtcm_addr(dtcm_addr_d), .ram_addr(ram_addr_d), .io_addr(io_addr_d), .sys_addr(),
        .itcm_we(itcm_we_d), .dtcm_we(dtcm_we_d), .ram_we(ram_we_d), .io_we(io_we_d), .sys_ctrl_we()
    );


    //  Instruction Fetch Bus (IF Stage) 
    wire [11:0] itcm_addr_i;
    wire itcm_sel_i;
    
    address_decoder instr_dec (
        .addr(pc), .we(1'b0), .re(1'b1), .wr_data(32'd0),
        .itcm_sel(itcm_sel_i), .dtcm_sel(), .ram_sel(), .io_sel(), .sys_ctrl_sel(),
        .itcm_addr(itcm_addr_i), .dtcm_addr(), .ram_addr(), .io_addr(), .sys_addr(),
        .itcm_we(), .dtcm_we(), .ram_we(), .io_we(), .sys_ctrl_we()
    );

    //  Memory Resources 
    wire [31:0] itcm_dout_a, itcm_dout_b, dtcm_rd_data, ram_rd_data;
    
    // ITCM (Instruction TCM) - 16 KB
    itcm itcm_inst (
        .clk(clk),
        .addr_a(itcm_addr_d),
        .din_a(dmem_wr_data),
        .we_a(itcm_we_d),
        .dout_a(itcm_dout_a),
        .addr_b(itcm_addr_i),
        .dout_b(itcm_dout_b)
    );
    assign instr_in = itcm_dout_b;

    // DTCM (Data TCM) - 8 KB
    dtcm dtcm_inst (
        .clk(clk), .addr(dtcm_addr_d), .din(dmem_wr_data), .we(dtcm_we_d),
        .dout(dtcm_rd_data)
    );

    // Main RAM - 32 MB
    ram_async #(.ADDR_WIDTH(23), .DEPTH(8388608)) ram_inst (
        .clk(clk), .addr(ram_addr_d), .wr_data(dmem_wr_data),
        .we(ram_we_d), .rd_data(ram_rd_data),
        .addr_b(23'd0), .rd_data_b()
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
    assign dmem_rd_data = ram_sel_d  ? ram_rd_data : 
                          itcm_sel_d ? itcm_dout_a : 
                          dtcm_sel_d ? dtcm_rd_data :
                          io_sel_d   ? io_rdata_bus : 32'd0;

    //  External Peripheral Ports 
    assign io_data_out = dmem_wr_data;
    assign io_addr_out = dmem_addr[15:0];
    assign io_we_out   = io_we_d;

endmodule
