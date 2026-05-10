`timescale 1ns / 1ps

/**
 * Module: io_peripheral_bus
 * Description: Parameterized peripheral bus using a slot-based architecture.
 *              Supports 16 slots, each with 256 bytes of address space.
 *              Adding a peripheral is done by updating the SLOT_CONFIG parameter.
 */
module io_peripheral_bus #(
    parameter NUM_SLOTS = 16,
    // SLOT_CONFIG defines the type of peripheral in each of the 16 slots (4 bits per slot).
    // Mapping: io_addr[11:8] selects the slot index.
    parameter [NUM_SLOTS*4-1:0] SLOT_CONFIG = {
        4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, // Slots 15-8: Empty
        4'h0, 4'h0, 4'h0, 4'h0,                         // Slots 7-4: Empty
        4'h4,                                           // Slot 3: INTC
        4'h3,                                           // Slot 2: UART
        4'h2,                                           // Slot 1: TIMER
        4'h1                                            // Slot 0: GPIO
    }
)(
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

    // Peripheral Type IDs
    localparam TYPE_NONE  = 4'h0,
               TYPE_GPIO  = 4'h1,
               TYPE_TIMER = 4'h2,
               TYPE_UART  = 4'h3,
               TYPE_INTC  = 4'h4;

    // Internal slot-level signals
    wire [NUM_SLOTS-1:0] slot_sel;
    wire [31:0]          slot_rdata [0:NUM_SLOTS-1];
    wire [NUM_SLOTS-1:0] slot_irqs;
    wire [NUM_SLOTS-1:0] slot_intc_irq_out;

    assign io_ready = 1'b1; // Default to zero-wait-state for simple peripherals
    assign irq_out  = |slot_intc_irq_out; // Combine IRQ outputs from any INTC slots

    // Gather all IRQ lines into a 32-bit vector for the Interrupt Controller
    wire [31:0] combined_irqs;
    assign combined_irqs = {{(32-NUM_SLOTS){1'b0}}, slot_irqs};

    // --- Slot Address Decoding ---
    generate
        genvar i;
        for (i = 0; i < NUM_SLOTS; i = i + 1) begin : sel_gen
            assign slot_sel[i] = (io_addr[11:8] == i[3:0]);
        end
    endgenerate

    // --- Read Data Multiplexing ---
    integer k;
    always @(*) begin
        io_rdata = 32'd0;
        for (k = 0; k < NUM_SLOTS; k = k + 1) begin
            if (slot_sel[k]) io_rdata = slot_rdata[k];
        end
    end

    // --- Dynamic Slot Instantiation ---
    generate
        for (i = 0; i < NUM_SLOTS; i = i + 1) begin : slots
            localparam [3:0] slot_type = SLOT_CONFIG[i*4 +: 4];
            
            if (slot_type == TYPE_GPIO) begin : gpio_slot
                gpio_top inst (
                    .clk(clk), .rst(rst),
                    .addr(io_addr[5:0]), .wdata(io_wdata), .we(io_we & slot_sel[i]), .re(io_re & slot_sel[i]),
                    .rdata(slot_rdata[i]),
                    .pins0(gpio0_pins), .pins1(gpio1_pins), .pins2(gpio2_pins), .pins3(gpio3_pins)
                );
                assign slot_irqs[i]         = 1'b0;
                assign slot_intc_irq_out[i] = 1'b0;
            end 
            else if (slot_type == TYPE_TIMER) begin : timer_slot
                wire t0_irq, t1_irq;
                timer_top inst (
                    .clk(clk), .rst(rst),
                    .addr(io_addr[4:0]), .wdata(io_wdata), .we(io_we & slot_sel[i]), .re(io_re & slot_sel[i]),
                    .rdata(slot_rdata[i]),
                    .irq0(t0_irq), .irq1(t1_irq)
                );
                assign slot_irqs[i]         = t0_irq | t1_irq;
                assign slot_intc_irq_out[i] = 1'b0;
            end 
            else if (slot_type == TYPE_UART) begin : uart_slot
                wire u_irq;
                uart_top inst (
                    .clk(clk), .rst(rst),
                    .addr(io_addr[3:0]), .wdata(io_wdata), .we(io_we & slot_sel[i]), .re(io_re & slot_sel[i]),
                    .rdata(slot_rdata[i]),
                    .tx(uart_tx), .rx(uart_rx),
                    .irq(u_irq)
                );
                assign slot_irqs[i]         = u_irq;
                assign slot_intc_irq_out[i] = 1'b0;
            end 
            else if (slot_type == TYPE_INTC) begin : intc_slot
                interrupt_controller inst (
                    .clk(clk), .rst(rst),
                    .addr(io_addr[3:0]), .wdata(io_wdata), .we(io_we & slot_sel[i]), .re(io_re & slot_sel[i]),
                    .rdata(slot_rdata[i]),
                    .irqs(combined_irqs),
                    .irq_out(slot_intc_irq_out[i])
                );
                assign slot_irqs[i] = 1'b0;
            end 
            else begin : empty_slot
                assign slot_rdata[i]        = (i == 4) ? 32'hDEAD_BEEF : 32'd0;
                assign slot_irqs[i]         = 1'b0;
                assign slot_intc_irq_out[i] = 1'b0;
            end
        end
    endgenerate

endmodule
