`timescale 1ns / 1ps

module l1_cache (
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

    wire [27:0] tag;
    wire [0:0]  index;
    wire [2:0]  offset;
    
    addr_decomp #(
        .ADDR_WIDTH(32),
        .LINE_SIZE(8),
        .NUM_SETS(2)
    ) decomp (
        .addr(addr),
        .tag(tag),
        .index(index),
        .block_offset(offset)
    );

    wire [27:0] rd_tag;
    wire [63:0] sram_rd_data;
    wire valid;
    wire dirty;

    reg [27:0] sram_wr_tag;
    reg [63:0] sram_wr_data;
    reg sram_we;

    cache_sram_way #(
        .INDEX_WIDTH(1),
        .TAG_WIDTH(28),
        .DATA_WIDTH(64)
    ) sram (
        .clk(clk),
        .index(index),
        .wr_tag(sram_wr_tag),
        .wr_data(sram_wr_data),
        .we(sram_we),
        .rd_tag(rd_tag),
        .rd_data(sram_rd_data),
        .valid(valid),
        .dirty(dirty)
    );

    localparam IDLE = 2'b00, ALLOCATE = 2'b01, WRITE_WAIT = 2'b10;
    reg [1:0] state, next_state;

    wire is_hit = valid && (rd_tag == tag);
    
    assign hit = (state == IDLE) && (re || we) && is_hit;
    assign miss = (state == IDLE) && (re || we) && !is_hit;

    reg stall_reg;
    reg mem_req_reg;
    reg mem_we_reg;
    reg [31:0] mem_addr_reg;
    
    always @(*) begin
        next_state = state;
        sram_we = 1'b0;
        sram_wr_tag = tag;
        sram_wr_data = sram_rd_data;
        stall_reg = 1'b0;
        mem_req_reg = 1'b0;
        mem_we_reg = 1'b0;
        mem_addr_reg = 32'b0;
        
        case (state)
            IDLE: begin
                if (re || we) begin
                    if (is_hit) begin
                        if (we) begin
                            sram_we = 1'b1;
                            sram_wr_data = offset[2] ? {wr_data, sram_rd_data[31:0]} : {sram_rd_data[63:32], wr_data};
                            
                            mem_req_reg = 1'b1;
                            mem_we_reg = 1'b1;
                            mem_addr_reg = addr;
                            if (!mem_ready) begin
                                stall_reg = 1'b1;
                                next_state = WRITE_WAIT;
                            end
                        end
                    end else begin
                        stall_reg = 1'b1;
                        mem_req_reg = 1'b1;
                        mem_addr_reg = {addr[31:3], 3'b000};
                        next_state = ALLOCATE;
                    end
                end
            end
            
            ALLOCATE: begin
                stall_reg = 1'b1;
                mem_req_reg = 1'b1;
                mem_addr_reg = {addr[31:3], 3'b000};
                if (mem_ready) begin
                    sram_we = 1'b1;
                    sram_wr_data = mem_data;
                    sram_wr_tag = tag;
                    next_state = IDLE;
                end
            end
            
            WRITE_WAIT: begin
                stall_reg = !mem_ready;
                mem_req_reg = 1'b1;
                mem_we_reg = 1'b1;
                mem_addr_reg = addr;
                if (mem_ready) begin
                    next_state = IDLE;
                end
            end
        endcase
    end

    always @(posedge clk) begin
        if (reset) state <= IDLE;
        else state <= next_state;
    end

    always @(*) begin
        rd_data = offset[2] ? sram_rd_data[63:32] : sram_rd_data[31:0];
    end

    assign stall = stall_reg;
    assign mem_req = mem_req_reg;
    assign mem_we = mem_we_reg;
    assign mem_addr = mem_addr_reg;
    assign mem_wr_data = wr_data;

endmodule
