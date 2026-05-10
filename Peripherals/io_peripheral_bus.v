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

    // Extensible Peripheral Slots
    localparam NUM_SLOTS = 16;
    wire [NUM_SLOTS-1:0] slot_sel;
    wire [31:0] slot_rdata [0:NUM_SLOTS-1];

    generate
        genvar i;
        for (i = 0; i < NUM_SLOTS; i = i + 1) begin : sel_gen
            assign slot_sel[i] = (io_addr[11:8] == i[3:0]);
        end
    endgenerate

    // Read Data Mux
    integer k;
    always @(*) begin
        io_rdata = 32'd0;
        for (k = 0; k < NUM_SLOTS; k = k + 1) begin
            if (slot_sel[k]) io_rdata = slot_rdata[k];
        end
    end

    // --- Slot Assignments ---
    assign slot_rdata[0] = gpio_rdata;
    assign slot_rdata[1] = timer_rdata;
    assign slot_rdata[2] = uart_rdata;
    assign slot_rdata[3] = intc_rdata;
    
    // Unassigned slots
    generate
        for (i = 4; i < NUM_SLOTS; i = i + 1) begin : unassigned_slots
            assign slot_rdata[i] = (i == 4) ? 32'hDEAD_BEEF : 32'd0;
        end
    endgenerate
    
    // Selection aliases for legacy wiring
    wire gpio_sel  = slot_sel[0];
    wire timer_sel = slot_sel[1];
    wire uart_sel  = slot_sel[2];
    wire intc_sel  = slot_sel[3];

    // Read Data wires
    wire [31:0] gpio_rdata, timer_rdata, uart_rdata, intc_rdata;
    
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


endmodule
