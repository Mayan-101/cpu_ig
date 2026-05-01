`timescale 1ns / 1ps

module l2_dcache (
    input  wire clk,
    input  wire rst,
    
    // CPU Interface
    input  wire [31:0] d_addr,
    input  wire [31:0] wr_data,
    input  wire we,
    input  wire re,
    output wire [31:0] rd_data,
    output wire [63:0] line_out, // Added for L1 64b fill
    output wire hit,
    output wire stall,
    
    // Memory Interface
    input  wire [63:0] mem_data,
    input  wire mem_ready,
    output wire mem_req,
    output wire [31:0] mem_addr,
    output wire mem_we,
    output wire [31:0] mem_wr_data
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
        .addr(d_addr),
        .wr_data(core_wr_data),
        .we(core_we),
        .re(re),
        .rd_data(core_rd_data),
        .hit(core_hit),
        .evict_way(core_evict_way),
        .evict_data(core_evict_data)
    );

    wire [2:0] offset = d_addr[2:0];

    localparam IDLE = 2'b00, ALLOCATE = 2'b01, WRITE_WAIT = 2'b10;
    reg [1:0] state, next_state;
    
    assign hit = (state == IDLE) && (re || we) && core_hit;
    
    reg stall_reg;
    reg mem_req_reg;
    reg mem_we_reg;
    reg [31:0] mem_addr_reg;
    
    always @(*) begin
        next_state = state;
        core_we = 1'b0;
        core_wr_data = core_rd_data;
        stall_reg = 1'b0;
        mem_req_reg = 1'b0;
        mem_we_reg = 1'b0;
        mem_addr_reg = 32'b0;
        
        case (state)
            IDLE: begin
                if (re || we) begin
                    if (core_hit) begin
                        if (we) begin
                            core_we = 1'b1;
                            core_wr_data = offset[2] ? {wr_data, core_rd_data[31:0]} : {core_rd_data[63:32], wr_data};
                            
                            mem_req_reg = 1'b1;
                            mem_we_reg = 1'b1;
                            mem_addr_reg = d_addr;
                            if (!mem_ready) begin
                                stall_reg = 1'b1;
                                next_state = WRITE_WAIT;
                            end
                        end
                    end else begin
                        stall_reg = 1'b1;
                        mem_req_reg = 1'b1;
                        mem_addr_reg = {d_addr[31:3], 3'b000};
                        next_state = ALLOCATE;
                    end
                end
            end
            
            ALLOCATE: begin
                stall_reg = 1'b1;
                mem_req_reg = 1'b1;
                mem_addr_reg = {d_addr[31:3], 3'b000};
                if (mem_ready) begin
                    core_we = 1'b1;
                    core_wr_data = mem_data;
                    next_state = IDLE;
                end
            end
            
            WRITE_WAIT: begin
                stall_reg = !mem_ready;
                mem_req_reg = 1'b1;
                mem_we_reg = 1'b1;
                mem_addr_reg = d_addr;
                if (mem_ready) begin
                    next_state = IDLE;
                end
            end
        endcase
    end

    always @(posedge clk) begin
        if (rst) state <= IDLE;
        else state <= next_state;
    end

    assign rd_data = offset[2] ? core_rd_data[63:32] : core_rd_data[31:0];
    assign line_out = core_rd_data;
    assign stall = stall_reg;
    assign mem_req = mem_req_reg;
    assign mem_we = mem_we_reg;
    assign mem_addr = mem_addr_reg;
    assign mem_wr_data = wr_data;

endmodule
