`timescale 1ns / 1ps

module io_peripheral_bus (
    input  wire        clk,
    input  wire        rst,
    
    // Interface from CPU/Decoder
    input  wire [31:0] io_addr,
    input  wire [31:0] io_wdata,
    input  wire        io_we,
    input  wire        io_re,
    input  wire [1:0]  io_size, // 00=byte, 01=half, 10=word
    
    output reg  [31:0] io_rdata,
    output wire        io_ready,
    
    // GPIO External Pins
    inout  wire [31:0] gpio0_pins,
    inout  wire [31:0] gpio1_pins,
    inout  wire [31:0] gpio2_pins,
    inout  wire [31:0] gpio3_pins,
    
    // UART External Pins
    output wire        uart_tx,
    input  wire        uart_rx,
    
    // Interrupt output to CPU
    output wire        irq_out
);

    // Peripheral Selection Signals (using relative addresses within 0x000-0xFFF)
    wire gpio_sel  = (io_addr[11:8] == 4'h0); // 0x000-0x0FF
    wire timer_sel = (io_addr[11:8] == 4'h1); // 0x100-0x1FF
    wire uart_sel  = (io_addr[11:8] == 4'h2); // 0x200-0x2FF
    wire intc_sel  = (io_addr[11:8] == 4'h3); // 0x300-0x3FF
    wire slot5_sel = (io_addr[11:8] == 4'h4); // 0x400-0x4FF (New Slot)

    // Read Data wires
    wire [31:0] gpio_rdata, timer_rdata, uart_rdata, intc_rdata;
    wire [31:0] slot5_rdata = 32'hDEAD_BEEF; // Default for unassigned slot
    
    // IRQ wires from peripherals
    wire timer0_irq, timer1_irq, uart_irq;

    // Ready signal (assume all ready for now)
    assign io_ready = 1'b1;

    // GPIO Instance
    gpio_top gpio_inst (
        .clk(clk), .rst(rst),
        .addr(io_addr[5:0]), .wdata(io_wdata), .we(io_we & gpio_sel), .re(io_re & gpio_sel),
        .rdata(gpio_rdata),
        .pins0(gpio0_pins), .pins1(gpio1_pins), .pins2(gpio2_pins), .pins3(gpio3_pins)
    );

    // Timer Instance
    timer_top timer_inst (
        .clk(clk), .rst(rst),
        .addr(io_addr[4:0]), .wdata(io_wdata), .we(io_we & timer_sel), .re(io_re & timer_sel),
        .rdata(timer_rdata),
        .irq0(timer0_irq), .irq1(timer1_irq)
    );

    // UART Instance
    uart_top uart_inst (
        .clk(clk), .rst(rst),
        .addr(io_addr[3:0]), .wdata(io_wdata), .we(io_we & uart_sel), .re(io_re & uart_sel),
        .rdata(uart_rdata),
        .tx(uart_tx), .rx(uart_rx),
        .irq(uart_irq)
    );

    // Interrupt Controller Instance
    interrupt_controller intc_inst (
        .clk(clk), .rst(rst),
        .addr(io_addr[3:0]), .wdata(io_wdata), .we(io_we & intc_sel), .re(io_re & intc_sel),
        .rdata(intc_rdata),
        .irqs({29'd0, uart_irq, timer1_irq, timer0_irq}), // Map sources to bits
        .irq_out(irq_out)
    );

    // Read Data Mux
    always @(*) begin
        if (gpio_sel)       io_rdata = gpio_rdata;
        else if (timer_sel) io_rdata = timer_rdata;
        else if (uart_sel)  io_rdata = uart_rdata;
        else if (intc_sel)  io_rdata = intc_rdata;
        else if (slot5_sel) io_rdata = slot5_rdata;
        else                io_rdata = 32'd0;
    end

endmodule
