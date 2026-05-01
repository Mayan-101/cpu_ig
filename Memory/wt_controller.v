`timescale 1ns / 1ps

module wt_controller (
    input  wire clk,
    input  wire rst,
    
    input  wire cache_hit,
    input  wire we,
    input  wire [31:0] addr,
    input  wire [31:0] data,
    output wire wt_pending,
    
    input  wire mem_ready,
    output wire mem_we,
    output wire [31:0] mem_addr,
    output wire [31:0] mem_data
);

    reg valid;
    reg [31:0] buf_addr;
    reg [31:0] buf_data;
    
    wire start_write = we && cache_hit;
    
    assign wt_pending = valid;

    assign mem_we = valid || start_write;
    assign mem_addr = valid ? buf_addr : addr;
    assign mem_data = valid ? buf_data : data;

    always @(posedge clk) begin
        if (rst) begin
            valid <= 1'b0;
            buf_addr <= 32'b0;
            buf_data <= 32'b0;
        end else begin
            if (valid) begin
                if (mem_ready) begin
                    valid <= 1'b0;
                end
            end else begin
                if (start_write && !mem_ready) begin
                    valid <= 1'b1;
                    buf_addr <= addr;
                    buf_data <= data;
                end
            end
        end
    end

endmodule
