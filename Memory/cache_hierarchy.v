`timescale 1ns / 1ps

module cache_hierarchy (
    input  wire clk,
    input  wire rst,
    
    // L1 Interface
    input  wire l1_miss,
    input  wire [31:0] l1_addr,
    output reg  fill_l1,
    output reg  [63:0] fill_data,
    output wire stall_pipeline,
    
    // L2 Interface
    input  wire l2_hit,
    input  wire [63:0] l2_data,
    
    // Memory Interface
    output reg  mem_req,
    output wire [31:0] mem_addr,
    input  wire mem_ready,
    input  wire [63:0] mem_data
);

    assign mem_addr = {l1_addr[31:3], 3'b000};
    
    localparam IDLE = 0, DELAY = 1, FETCH = 2;
    reg [1:0] state, next_state;
    reg [2:0] delay_cnt, next_delay_cnt;

    assign stall_pipeline = l1_miss;

    always @(*) begin
        next_state = state;
        next_delay_cnt = delay_cnt;
        fill_l1 = 0;
        fill_data = 64'b0;
        mem_req = 0;
        
        case (state)
            IDLE: begin
                if (l1_miss) begin
                    if (l2_hit) begin
                        next_delay_cnt = 3;
                        next_state = DELAY;
                    end else begin
                        mem_req = 1;
                        next_state = FETCH;
                    end
                end
            end
            
            DELAY: begin
                if (delay_cnt == 0) begin
                    fill_l1 = 1;
                    fill_data = l2_data;
                    next_state = IDLE;
                end else begin
                    next_delay_cnt = delay_cnt - 1;
                end
            end
            
            FETCH: begin
                mem_req = 1;
                if (mem_ready) begin
                    fill_l1 = 1;
                    fill_data = mem_data;
                    next_state = IDLE;
                end
            end
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            delay_cnt <= 0;
        end else begin
            state <= next_state;
            delay_cnt <= next_delay_cnt;
        end
    end

endmodule
