`timescale 1ns / 1ps

module tb_l2_cache;

    reg clk;
    reg rst;
    
    reg [31:0] addr;
    reg [31:0] wr_data;
    reg we;
    reg re;
    wire [31:0] rd_data;
    wire hit;
    wire stall;
    
    reg [63:0] mem_data;
    reg mem_ready;
    wire mem_req;
    wire [31:0] mem_addr;
    wire mem_we;
    wire [31:0] mem_wr_data;

    l2_cache dut (
        .clk(clk),
        .rst(rst),
        .addr(addr),
        .wr_data(wr_data),
        .we(we),
        .re(re),
        .rd_data(rd_data),
        .hit(hit),
        .stall(stall),
        .mem_data(mem_data),
        .mem_ready(mem_ready),
        .mem_req(mem_req),
        .mem_addr(mem_addr),
        .mem_we(mem_we),
        .mem_wr_data(mem_wr_data)
    );

    always #5 clk = ~clk;

    initial begin
        mem_ready = 0;
        forever begin
            @(posedge clk);
            if (mem_req && !mem_ready) begin
                if (!mem_we) begin
                    repeat (3) @(posedge clk);
                    mem_data = {mem_addr[31:0], mem_addr[31:0]}; // Dummy data
                    mem_ready = 1;
                end else begin
                    repeat (2) @(posedge clk);
                    mem_ready = 1;
                end
            end else if (mem_ready) begin
                mem_ready = 0;
            end
        end
    end

    task write_cache(input [31:0] a, input [31:0] d, output h);
    begin
        @(negedge clk);
        addr = a;
        wr_data = d;
        we = 1;
        #1;
        h = hit;
        if (stall) begin
            wait(stall == 0);
        end
        @(negedge clk);
        we = 0;
    end
    endtask

    task read_cache(input [31:0] a, output h, output [31:0] d);
    begin
        @(negedge clk);
        addr = a;
        re = 1;
        #1;
        h = hit;
        if (stall) begin
            wait(stall == 0);
        end
        @(negedge clk);
        d = rd_data;
        re = 0;
    end
    endtask

    reg h_res;
    reg [31:0] d_res;

    initial begin
        $display("--- Unified L2 Cache Test ---");
        clk = 0;
        rst = 1;
        addr = 0;
        wr_data = 0;
        we = 0;
        re = 0;
        
        #15;
        rst = 0;
        
        // Write miss -> stall + mem fetch + allocate + write
        write_cache(32'h00000010, 32'hDEADBEEF, h_res);
        if (h_res) $display("FAIL: Expected miss on initial write");
        
        // Write hit -> data updated + mem_we=1 same cycle
        write_cache(32'h00000014, 32'hCAFEF00D, h_res);
        if (!h_res) $display("FAIL: Expected hit on subsequent write");
        
        // Read hit after write -> correct data
        read_cache(32'h00000010, h_res, d_res);
        if (!h_res || d_res !== 32'hDEADBEEF) $display("FAIL: Read 10, Hit=%b Data=%h", h_res, d_res);
        
        read_cache(32'h00000014, h_res, d_res);
        if (!h_res || d_res !== 32'hCAFEF00D) $display("FAIL: Read 14, Hit=%b Data=%h", h_res, d_res);

        // Read miss -> stall + fetch
        read_cache(32'h00000020, h_res, d_res);
        if (h_res) $display("FAIL: Expected miss on 20");
        if (d_res !== 32'h00000020) $display("FAIL: Expected 00000020 from memory, got %h", d_res);

        $display("L2 Cache Test finished.");
        $finish;
    end

endmodule
