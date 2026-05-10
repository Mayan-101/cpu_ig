`timescale 1ns / 1ps

module uart_top (
    input  wire        clk,
    input  wire        rst,
    input  wire [3:0]  addr,
    input  wire [31:0] wdata,
    input  wire        we,
    input  wire        re,
    output reg  [31:0] rdata,
    output reg         tx,
    input  wire        rx,
    output wire        irq
);
    // UART Registers
    reg [7:0]  tx_buffer;
    reg [31:0] status; // bit 0: tx_ready, bit 1: rx_valid, bit 2: tx_busy
    reg [31:0] ctrl;   // bit 0: tx_en, bit 1: rx_en
    reg [15:0] baud_div = 16'd434; // Default for 50MHz @ 115200
    
    // TX State Machine
    reg [3:0] tx_state;
    reg [3:0] bit_idx;
    reg [15:0] baud_count;
    reg [9:0] tx_shift_reg;
    
    localparam TX_IDLE  = 4'd0,
               TX_START = 4'd1,
               TX_DATA  = 4'd2,
               TX_STOP  = 4'd3;

    assign irq = status[1]; // RX valid interrupt

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            status     <= 32'h0000_0001; // TX Ready
            ctrl       <= 0;
            tx         <= 1'b1;
            tx_state   <= TX_IDLE;
            baud_count <= 0;
        end else begin
            // Register Writes
            if (we) begin
                case (addr)
                    4'h0: begin // TX Data
                        if (status[0]) begin
                            tx_buffer <= wdata[7:0];
                            status[0] <= 1'b0; // Not ready
                        end
                    end
                    4'hC: ctrl <= wdata;
                endcase
            end

            // TX State Machine
            case (tx_state)
                TX_IDLE: begin
                    tx <= 1'b1;
                    if (!status[0]) begin // Data loaded
                        tx_shift_reg <= {1'b1, tx_buffer, 1'b0}; // Stop, Data, Start
                        tx_state     <= TX_START;
                        baud_count   <= 0;
                        status[2]    <= 1'b1; // Busy
                    end
                end
                TX_START, TX_DATA, TX_STOP: begin
                    if (baud_count >= baud_div) begin
                        baud_count <= 0;
                        tx <= tx_shift_reg[0];
                        tx_shift_reg <= {1'b1, tx_shift_reg[9:1]};
                        
                        if (bit_idx == 4'd9) begin
                            bit_idx  <= 0;
                            tx_state <= TX_IDLE;
                            status[0] <= 1'b1; // Ready for next
                            status[2] <= 1'b0; // Not busy
                        end else begin
                            bit_idx <= bit_idx + 1;
                            tx_state <= (bit_idx == 4'd0) ? TX_DATA : 
                                        (bit_idx == 4'd8) ? TX_STOP : TX_DATA;
                        end
                    end else begin
                        baud_count <= baud_count + 1;
                    end
                end
            endcase
        end
    end

    always @(*) begin
        case (addr)
            4'h0: rdata = 32'd0;
            4'h4: rdata = 32'd0; // rx_data
            4'h8: rdata = status;
            4'hC: rdata = ctrl;
            default: rdata = 32'd0;
        endcase
    end
endmodule

