/*
 * Module: system_cache_top
 * Description: Canonical SoC integration top (no external cache).
 *              CPU ↔ ITCM (16 KB) ↔ DTCM (8 KB) ↔ RAM (16 MB) ↔ I/O Bus.
 *              Memory map:
 *                ITCM  0x0000_0000 – 0x0000_3FFF  (16 KB, dual-port)
 *                DTCM  0x0001_0000 – 0x0001_1FFF  (8 KB)
 *                RAM   0x1000_0000 – 0x10FF_FFFF  (16 MB)
 *                I/O   0x4000_0000 – 0x4FFF_FFFF  (256 MB peripheral space)
 */
module system_cache_top (
    input  wire        clk,
    input  wire        rst,
    output wire [31:0] io_data_out,
    output wire [15:0] io_addr_out,
    output wire        io_we_out,
    output wire        stall_cpu,   // Reserved – tied low; placeholder for future cache integration
    output wire        halt_cpu
);

    // =========================================================================
    //  Internal Bus Signals
    // =========================================================================
    wire [31:0] pc;                          // Instruction fetch address
    wire [31:0] instr_in;                    // Instruction word from ITCM port-B

    wire [31:0] dmem_addr, dmem_wr_data, dmem_rd_data;
    wire        dmem_we, dmem_re;

    wire [31:0] io_rdata_bus;               // Read-data returned from I/O peripheral bus
    wire        irq_line;                    // Interrupt request from I/O peripheral bus

    // =========================================================================
    //  CPU Core
    // =========================================================================
    cpu_top cpu (
        .clk          (clk),
        .rst          (rst),

        // Instruction bus – ITCM port-B, always ready (1-cycle latency)
        .ibus_addr    (pc),
        .ibus_rdata   (instr_in),
        .ibus_ready   (1'b1),

        // Data bus – muxed across DTCM / RAM / I/O
        .dbus_addr    (dmem_addr),
        .dbus_wdata   (dmem_wr_data),
        .dbus_we      (dmem_we),
        .dbus_re      (dmem_re),
        .dbus_rdata   (dmem_rd_data),
        .dbus_ready   (1'b1),

        // Peripheral read path (I/O IN instructions)
        .dbus_io_rdata(io_rdata_bus),

        // System signals
        .irq          (irq_line),
        .halt_cpu     (halt_cpu)
    );

    // =========================================================================
    //  Address Decode (inline – simple range comparisons)
    // =========================================================================
    wire is_itcm_fetch = (pc        <  32'h0000_4000);
    wire is_itcm_data  = (dmem_addr <  32'h0000_4000);
    wire is_dtcm       = (dmem_addr >= 32'h0001_0000) && (dmem_addr <= 32'h0001_1FFF);
    wire is_ram        = (dmem_addr >= 32'h1000_0000) && (dmem_addr <= 32'h10FF_FFFF);
    wire is_io         = (dmem_addr >= 32'h4000_0000) && (dmem_addr <= 32'h4FFF_FFFF);

    // =========================================================================
    //  ITCM – 16 KB, dual-port (port-A: data RW, port-B: instruction fetch)
    // =========================================================================
    wire [31:0] itcm_data;
    itcm itcm_inst (
        .clk    (clk),
        .addr_a (dmem_addr[13:2]),
        .din_a  (dmem_wr_data),
        .we_a   (dmem_we && is_itcm_data),
        .dout_a (itcm_data),
        .addr_b (pc[13:2]),
        .dout_b (instr_in)
    );

    // =========================================================================
    //  DTCM – 8 KB
    // =========================================================================
    wire [31:0] dtcm_data;
    dtcm dtcm_inst (
        .clk  (clk),
        .addr (dmem_addr[12:2]),
        .din  (dmem_wr_data),
        .we   (dmem_we && is_dtcm),
        .dout (dtcm_data)
    );

    // =========================================================================
    //  Main RAM – 16 MB
    // =========================================================================
    wire [31:0] ram_data;
    ram_async #(.ADDR_WIDTH(22), .DEPTH(4194304)) main_ram (
        .clk      (clk),
        .addr     (dmem_addr[23:2]),
        .wr_data  (dmem_wr_data),
        .we       (dmem_we && is_ram),
        .rd_data  (ram_data),
        .addr_b   (22'd0),
        .rd_data_b()
    );

    // =========================================================================
    //  Data Read Mux
    // =========================================================================
    assign dmem_rd_data = is_dtcm      ? dtcm_data :
                          is_ram       ? ram_data   :
                          is_itcm_data ? itcm_data  : 32'd0;

    // =========================================================================
    //  I/O Peripheral Bus
    // =========================================================================
    io_peripheral_bus io_bus (
        .clk      (clk),
        .rst      (rst),
        .io_addr  (dmem_addr),
        .io_wdata (dmem_wr_data),
        .io_we    (dmem_we  && is_io),
        .io_re    (dmem_re  && is_io),
        .io_size  (2'b10),
        .io_rdata (io_rdata_bus),
        .io_ready (),
        .gpio0_pins(), .gpio1_pins(), .gpio2_pins(), .gpio3_pins(),
        .uart_tx  (),
        .uart_rx  (1'b1),
        .irq_out  (irq_line)
    );

    // =========================================================================
    //  Exported Peripheral Observation Ports (for simulation / FPGA top)
    // =========================================================================
    assign io_data_out = dmem_wr_data;
    assign io_addr_out = dmem_addr[15:0];
    assign io_we_out   = dmem_we && is_io;

    // stall_cpu is reserved for future cache integration
    assign stall_cpu   = 1'b0;

endmodule
