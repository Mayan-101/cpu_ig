`timescale 1ns / 1ps

module l1_cache #(
    parameter INDEX_WIDTH = 5,
    parameter TAG_WIDTH = 24
)(
    input  wire clk,
    input  wire reset,
    
    // CPU Interface
    input  wire [31:0] addr,
    input  wire [31:0] wr_data,
    input  wire we,
    input  wire re,
    output reg  [31:0] rd_data,
    output wire hit,
    output wire miss,
    output wire stall,
    
    // Memory Interface
    input  wire [63:0] mem_data,
    input  wire mem_ready,
    output wire mem_req,
    output wire [31:0] mem_addr,
    output wire mem_we,
    output wire [31:0] mem_wr_data
);

    wire [TAG_WIDTH-1:0] tag;
    wire [INDEX_WIDTH-1:0] index;
    wire [2:0]  offset;
    
    addr_decomp #(
        .ADDR_WIDTH(32),
        .LINE_SIZE(8),
        .NUM_SETS(1 << INDEX_WIDTH)
    ) decomp (
        .addr(addr),
        .tag(tag),
        .index(index),
        .block_offset(offset)
    );

    wire [63:0] sram_rd_data;
    wire core_hit;
    wire [1:0] evict_way;
    wire [63:0] evict_data;

    cache_core_4way #(
        .INDEX_WIDTH(INDEX_WIDTH),
        .TAG_WIDTH(TAG_WIDTH),
        .DATA_WIDTH(64)
    ) core (
        .clk(clk),
        .rst(reset),
        .addr(addr),
        .wr_data(sram_wr_data),
        .we(sram_we),
        .re(re),
        .rd_data(sram_rd_data),
        .hit(core_hit),
        .evict_way(evict_way),
        .evict_data(evict_data)
    );

    localparam IDLE = 2'b00, ALLOCATE = 2'b01, WRITE_WAIT = 2'b10;
    reg [1:0] state, next_state;

    wire is_hit = core_hit;
    assign hit = (state == IDLE) && (re || we) && is_hit;
    assign miss = (state == IDLE) && (re || we) && !is_hit;
    
    // Stall logic: Default to stalling if state is unknown or if we have a miss
    assign stall = (state != IDLE) || (miss && !is_hit) || (we && !serviced && !reset); 
    
    reg mem_req_reg;
    reg mem_we_reg;
    reg [31:0] mem_addr_reg;
    reg [31:0] mem_wr_data_reg;
    reg [63:0] sram_wr_data;
    reg sram_we;
    
    always @(*) begin
        next_state = state;
        sram_we = 1'b0;
        sram_wr_data = sram_rd_data;
        mem_req_reg = 1'b0;
        mem_addr_reg = 32'b0;
        mem_we_reg = 1'b0;
        mem_wr_data_reg = 32'b0;

        case (state)
            IDLE: begin
                if (miss && !serviced) begin
                    mem_req_reg = 1'b1;
                    mem_addr_reg = {addr[31:3], 3'b000};
                    next_state = ALLOCATE;
                end else if (we && !serviced && is_hit) begin
                    sram_we = 1'b1;
                    sram_wr_data = offset[2] ? {wr_data, sram_rd_data[31:0]} : {sram_rd_data[63:32], wr_data};
                    mem_req_reg = 1'b1;
                    mem_we_reg = 1'b1;
                    mem_addr_reg = addr;
                    if (!mem_ready) next_state = WRITE_WAIT;
                end
            end
            
            ALLOCATE: begin
                mem_req_reg = 1'b1;
                mem_addr_reg = {addr[31:3], 3'b000};
                if (mem_ready) begin
                    sram_we = 1'b1;
                    sram_wr_data = mem_data;
                    next_state = IDLE;
                end
            end
            
            WRITE_WAIT: begin
                mem_req_reg = 1'b1;
                mem_we_reg = 1'b1;
                mem_addr_reg = addr;
                if (mem_ready) next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end

    reg serviced;
    reg [31:0] last_addr;
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            serviced <= 1'b0;
            last_addr <= 32'hFFFF_FFFF;
        end else begin
            state <= next_state;
            last_addr <= addr;
            
            if (addr != last_addr)
                serviced <= 1'b0;
            
            if (state == IDLE && (hit || next_state == ALLOCATE || next_state == WRITE_WAIT))
                serviced <= 1'b1;
                
            if (!(re || we))
                serviced <= 1'b0;
        end
    end

    always @(*) begin
        rd_data = offset[2] ? sram_rd_data[63:32] : sram_rd_data[31:0];
    end

    assign mem_req = mem_req_reg;
    assign mem_we = mem_we_reg;
    assign mem_addr = mem_addr_reg;
    assign mem_wr_data = wr_data;

endmodule
