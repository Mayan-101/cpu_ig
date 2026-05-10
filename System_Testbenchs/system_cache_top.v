/*
 * Module: system_cache_top (ZERO LATENCY VERSION)
 */
module system_cache_top (
    input  wire        clk,
    input  wire        rst,
    output wire [31:0] io_data_out,
    output wire [15:0] io_addr_out,
    output wire        io_we_out,
    output wire        stall_cpu,
    output wire        halt_cpu
);

    wire [31:0] pc, instr_in;
    wire [31:0] dmem_addr, dmem_wr_data, dmem_rd_data;
    wire        dmem_we, dmem_re;
    wire        irq_signal;
    wire [31:0] io_rdata_bus;

    cpu_top cpu (
        .clk(clk), .rst(rst),
        .ibus_addr(pc), .ibus_rdata(instr_in), .ibus_ready(1'b1),
        .dbus_addr(dmem_addr), .dbus_wdata(dmem_wr_data), .dbus_we(dmem_we), .dbus_re(dmem_re),
        .dbus_rdata(dmem_rd_data), .dbus_ready(1'b1),
        .dbus_io_rdata(io_rdata_bus),
        .irq(irq_signal),
        .halt_cpu(halt_cpu)
    );


    wire [31:0] itcm_data, dtcm_data, ram_data;
    wire is_itcm = (pc < 32'h0000_4000); // 16 KB
    wire is_ram  = (dmem_addr >= 32'h1000_0000 && dmem_addr <= 32'h10FF_FFFF);
    wire is_dtcm = (dmem_addr >= 32'h0001_0000 && dmem_addr <= 32'h0001_1FFF); // 8 KB
    wire is_itcm_data = (dmem_addr < 32'h0000_4000); // 16 KB

    // ITCM (Instruction TCM) - 16 KB
    itcm itcm_inst (
        .clk(clk),
        .addr_a(dmem_addr[13:2]),
        .din_a(dmem_wr_data),
        .we_a(dmem_we && is_itcm_data),
        .dout_a(itcm_data),
        .addr_b(pc[13:2]),
        .dout_b(instr_in)
    );

    // DTCM (Data TCM) - 8 KB
    dtcm dtcm_inst (
        .clk(clk),
        .addr(dmem_addr[12:2]),
        .din(dmem_wr_data),
        .we(dmem_we && is_dtcm),
        .dout(dtcm_data)
    );

    // Main RAM - 16 MB
    ram_async #(.ADDR_WIDTH(22), .DEPTH(4194304)) main_ram (
        .clk(clk), .addr(dmem_addr[23:2]), .wr_data(dmem_wr_data), .we(dmem_we && is_ram),
        .rd_data(ram_data),
        .addr_b(22'd0), .rd_data_b()
    );

    assign dmem_rd_data = is_dtcm ? dtcm_data : 
                          is_ram  ? ram_data  : 
                          is_itcm_data ? itcm_data : 32'd0;
    
    assign stall_cpu = 1'b0;

    //  I/O Peripheral Bus 
    wire io_sel_d = (dmem_addr >= 32'h4000_0000 && dmem_addr <= 32'h4FFF_FFFF);
    io_peripheral_bus io_bus (
        .clk(clk), .rst(rst),
        .io_addr(dmem_addr), .io_wdata(dmem_wr_data), .io_we(dmem_we & io_sel_d), .io_re(dmem_re & io_sel_d), .io_size(2'b10),
        .io_rdata(io_rdata_bus), .io_ready(),
        .gpio0_pins(), .gpio1_pins(), .gpio2_pins(), .gpio3_pins(),
        .uart_tx(), .uart_rx(1'b1),
        .irq_out(irq_signal)
    );

    assign io_data_out = dmem_wr_data;
    assign io_addr_out = dmem_addr[15:0];
    assign io_we_out   = dmem_we & io_sel_d;

endmodule
