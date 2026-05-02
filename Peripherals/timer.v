`timescale 1ns / 1ps

module timer_top (
    input  wire        clk,
    input  wire        rst,
    input  wire [4:0]  addr,
    input  wire [31:0] wdata,
    input  wire        we,
    input  wire        re,
    output reg  [31:0] rdata,
    output wire        irq0,
    output wire        irq1
);
    // Timer 0
    reg [31:0] t0_load, t0_count, t0_ctrl;
    reg t0_irq_reg;
    
    // Timer 1
    reg [31:0] t1_load, t1_count, t1_ctrl;
    reg t1_irq_reg;

    assign irq0 = t0_irq_reg;
    assign irq1 = t1_irq_reg;

    // Control bits: [0]=enable, [1]=auto-reload
    
    always @(posedge clk) begin
        if (rst) begin
            t0_load <= 0; t0_count <= 0; t0_ctrl <= 0; t0_irq_reg <= 0;
            t1_load <= 0; t1_count <= 0; t1_ctrl <= 0; t1_irq_reg <= 0;
        end else begin
            // Timer 0 Logic
            if (t0_ctrl[0]) begin
                if (t0_count == 0) begin
                    t0_irq_reg <= 1'b1;
                    if (t0_ctrl[1]) t0_count <= t0_load;
                    else t0_ctrl[0] <= 1'b0; // Disable one-shot
                end else begin
                    t0_count <= t0_count - 1;
                end
            end
            
            // Timer 1 Logic
            if (t1_ctrl[0]) begin
                if (t1_count == 0) begin
                    t1_irq_reg <= 1'b1;
                    if (t1_ctrl[1]) t1_count <= t1_load;
                    else t1_ctrl[0] <= 1'b0;
                end else begin
                    t1_count <= t1_count - 1;
                end
            end

            // Bus access
            if (we) begin
                case (addr[4:2])
                    3'b000: t0_load <= wdata;
                    3'b001: t0_count <= wdata;
                    3'b010: t0_ctrl <= wdata;
                    3'b011: t0_irq_reg <= 1'b0; // Clear IRQ on write to INT reg
                    3'b100: t1_load <= wdata;
                    3'b101: t1_count <= wdata;
                    3'b110: t1_ctrl <= wdata;
                    3'b111: t1_irq_reg <= 1'b0;
                endcase
            end
        end
    end

    always @(*) begin
        case (addr[4:2])
            3'b000: rdata = t0_load;
            3'b001: rdata = t0_count;
            3'b010: rdata = t0_ctrl;
            3'b011: rdata = {31'd0, t0_irq_reg};
            3'b100: rdata = t1_load;
            3'b101: rdata = t1_count;
            3'b110: rdata = t1_ctrl;
            3'b111: rdata = {31'd0, t1_irq_reg};
            default: rdata = 32'd0;
        endcase
    end
endmodule
