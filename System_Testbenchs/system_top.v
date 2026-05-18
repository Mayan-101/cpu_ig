/*
 * Module: system_top
 * Description: Alternative SoC integration using explicit address_decoder module.
 *              Kept for reference / FPGA synthesis flows that need the decoder as a
 *              separate, independently-constrainable block.
 *              For simulation use system_cache_top instead.
 *
 *  Memory map (matches address_decoder.v):
 *    ITCM  0x0000_0000 – 0x0000_3FFF  (16 KB)
 *    DTCM  0x0001_0000 – 0x0001_1FFF  (8 KB)
 *    RAM   0x1000_0000 – 0x11FF_FFFF  (32 MB)
 *    I/O   0x4000_0000 – 0x4FFF_FFFF
 *    SYS   0x8000_0000 – 0x8000_0FFF
 */
module system_top (
    input  wire        clk,
    input  wire        rst,
    output wire [31:0] io_data_out,
    output wire [15:0] io_addr_out,
    output wire        io_we_out,
    output wire        halt_cpu
);

    // =========================================================================
    //  Internal Bus Interconnects
    // =========================================================================
    wire [31:0] pc, instr_in;
    wire [31:0] dmem_addr, dmem_wr_data, dmem_rd_data;
    wire        dmem_we, dmem_re;
    wire [31:0] io_rdata_bus;
    wire        irq_line;

    // =========================================================================
    //  CPU Core
    // =========================================================================
    cpu_top cpu (
        .clk          (clk),
        .rst          (rst),
        .ibus_addr    (pc),
        .ibus_rdata   (instr_in),
        .ibus_ready   (1'b1),
        .dbus_addr    (dmem_addr),
        .dbus_wdata   (dmem_wr_data),
        .dbus_we      (dmem_we),
        .dbus_re      (dmem_re),
        .dbus_rdata   (dmem_rd_data),
        .dbus_ready   (1'b1),
        .dbus_io_rdata(io_rdata_bus),
        .irq          (irq_line),
        .halt_cpu     (halt_cpu)
    );

    // =========================================================================
    //  Data Bus Address Decoder
    // =========================================================================
    wire itcm_sel_d, dtcm_sel_d, ram_sel_d, io_sel_d;
    wire [11:0] itcm_addr_d;
    wire [10:0] dtcm_addr_d;
    wire [22:0] ram_addr_d;
    wire        itcm_we_d, dtcm_we_d, ram_we_d, io_we_d;

    address_decoder data_dec (
        .addr        (dmem_addr),
        .we          (dmem_we),
        .re          (dmem_re),
        .wr_data     (dmem_wr_data),
        .itcm_sel    (itcm_sel_d),
        .dtcm_sel    (dtcm_sel_d),
        .ram_sel     (ram_sel_d),
        .io_sel      (io_sel_d),
        .sys_ctrl_sel(),
        .itcm_addr   (itcm_addr_d),
        .dtcm_addr   (dtcm_addr_d),
        .ram_addr    (ram_addr_d),
        .io_addr     (),
        .sys_addr    (),
        .itcm_we     (itcm_we_d),
        .dtcm_we     (dtcm_we_d),
        .ram_we      (ram_we_d),
        .io_we       (io_we_d),
        .sys_ctrl_we ()
    );

    // =========================================================================
    //  Instruction Fetch Address Decoder
    // =========================================================================
    wire [11:0] itcm_addr_i;
    address_decoder instr_dec (
        .addr        (pc),
        .we          (1'b0),
        .re          (1'b1),
        .wr_data     (32'd0),
        .itcm_sel    (),
        .dtcm_sel    (),
        .ram_sel     (),
        .io_sel      (),
        .sys_ctrl_sel(),
        .itcm_addr   (itcm_addr_i),
        .dtcm_addr   (),
        .ram_addr    (),
        .io_addr     (),
        .sys_addr    (),
        .itcm_we     (),
        .dtcm_we     (),
        .ram_we      (),
        .io_we       (),
        .sys_ctrl_we ()
    );

    // =========================================================================
    //  ITCM – 16 KB, dual-port
    // =========================================================================
    wire [31:0] itcm_dout_a, itcm_dout_b;
    itcm itcm_inst (
        .clk    (clk),
        .addr_a (itcm_addr_d),
        .din_a  (dmem_wr_data),
        .we_a   (itcm_we_d),
        .dout_a (itcm_dout_a),
        .addr_b (itcm_addr_i),
        .dout_b (itcm_dout_b)
    );
    assign instr_in = itcm_dout_b;

    // =========================================================================
    //  DTCM – 8 KB
    // =========================================================================
    wire [31:0] dtcm_rd_data;
    dtcm dtcm_inst (
        .clk  (clk),
        .addr (dtcm_addr_d),
        .din  (dmem_wr_data),
        .we   (dtcm_we_d),
        .dout (dtcm_rd_data)
    );

    // =========================================================================
    //  Main RAM – 32 MB
    // =========================================================================
    wire [31:0] ram_rd_data;
    ram_async #(.ADDR_WIDTH(23), .DEPTH(8388608)) ram_inst (
        .clk      (clk),
        .addr     (ram_addr_d),
        .wr_data  (dmem_wr_data),
        .we       (ram_we_d),
        .rd_data  (ram_rd_data),
        .addr_b   (23'd0),
        .rd_data_b()
    );

    // =========================================================================
    //  I/O Peripheral Bus
    // =========================================================================
    io_peripheral_bus io_bus (
        .clk      (clk),
        .rst      (rst),
        .io_addr  (dmem_addr),
        .io_wdata (dmem_wr_data),
        .io_we    (io_we_d),
        .io_re    (dmem_re && io_sel_d),
        .io_size  (2'b10),
        .io_rdata (io_rdata_bus),
        .io_ready (),
        .gpio0_pins(), .gpio1_pins(), .gpio2_pins(), .gpio3_pins(),
        .uart_tx  (),
        .uart_rx  (1'b1),
        .irq_out  (irq_line)
    );

    // =========================================================================
    //  Data Read Mux
    // =========================================================================
    assign dmem_rd_data = ram_sel_d  ? ram_rd_data  :
                          itcm_sel_d ? itcm_dout_a  :
                          dtcm_sel_d ? dtcm_rd_data :
                          io_sel_d   ? io_rdata_bus : 32'd0;

    // =========================================================================
    //  Exported Peripheral Observation Ports
    // =========================================================================
    assign io_data_out = dmem_wr_data;
    assign io_addr_out = dmem_addr[15:0];
    assign io_we_out   = io_we_d;

endmodule
