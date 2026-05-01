`timescale 1ns / 1ps

module l2_icache (
    input  wire clk,
    input  wire rst,
    
    // CPU Pipeline Interface
    input  wire [31:0] i_addr,
    input  wire re,
    output wire [63:0] instr_data,
    output wire hit,
    output wire stall,
    
    // Memory Interface
    input  wire [63:0] mem_data,
    input  wire mem_ready,
    output wire mem_req,
    output wire [31:0] mem_addr
);

    wire [63:0] core_rd_data;
    wire core_hit;
    wire [1:0] core_evict_way;
    wire [63:0] core_evict_data;
    
    reg core_we;
    reg [63:0] core_wr_data;
    
    cache_core_4way #(
        .INDEX_WIDTH(1), // 2 sets
        .TAG_WIDTH(28),
        .DATA_WIDTH(64)
    ) core (
        .clk(clk),
        .rst(rst),
        .addr(i_addr),
        .wr_data(core_wr_data),
        .we(core_we),
        .re(re),
        .rd_data(core_rd_data),
        .hit(core_hit),
        .evict_way(core_evict_way),
        .evict_data(core_evict_data)
    );

    localparam IDLE = 1'b0, ALLOCATE = 1'b1;
    reg state, next_state;
    
    assign hit = (state == IDLE) && re && core_hit;
    
    reg stall_reg;
    reg mem_req_reg;
    reg [31:0] mem_addr_reg;
    
    always @(*) begin
        next_state = state;
        core_we = 1'b0;
        core_wr_data = mem_data;
        stall_reg = 1'b0;
        mem_req_reg = 1'b0;
        mem_addr_reg = 32'b0;
        
        case (state)
            IDLE: begin
                if (re) begin
                    if (!core_hit) begin
                        stall_reg = 1'b1;
                        mem_req_reg = 1'b1;
                        mem_addr_reg = {i_addr[31:3], 3'b000};
                        next_state = ALLOCATE;
                    end
                end
            end
            
            ALLOCATE: begin
                stall_reg = 1'b1;
                mem_req_reg = 1'b1;
                mem_addr_reg = {i_addr[31:3], 3'b000};
                if (mem_ready) begin
                    core_we = 1'b1;
                    core_wr_data = mem_data;
                    next_state = IDLE;
                end
            end
        endcase
    end

    always @(posedge clk) begin
        if (rst) state <= IDLE;
        else state <= next_state;
    end

    assign instr_data = core_rd_data;
    assign stall = stall_reg;
    assign mem_req = mem_req_reg;
    assign mem_addr = mem_addr_reg;

endmodule
