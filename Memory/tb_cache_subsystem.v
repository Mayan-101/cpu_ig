`timescale 1ns / 1ps

module tb_cache_subsystem;

    reg clk;
    reg rst;
    
    reg [31:0] addr;
    reg [31:0] wr_data;
    reg we;
    reg re;
    reg is_instr;
    wire [31:0] rd_data;
    wire hit;
    wire stall;
    
    reg [63:0] mem_data;
    reg mem_ready;
    wire mem_req;
    wire mem_we;
    wire [31:0] mem_addr;
    wire [31:0] mem_wr_data;

    cache_subsystem dut (
        .clk(clk),
        .rst(rst),
        .addr(addr),
        .wr_data(wr_data),
        .we(we),
        .re(re),
        .is_instr(is_instr),
        .rd_data(rd_data),
        .hit(hit),
        .stall(stall),
        .mem_data(mem_data),
        .mem_ready(mem_ready),
        .mem_req(mem_req),
        .mem_we(mem_we),
        .mem_addr(mem_addr),
        .mem_wr_data(mem_wr_data)
    );

    always #5 clk = ~clk;

    initial begin
        mem_ready = 0;
        forever begin
            @(posedge clk);
            if (mem_req && !mem_ready) begin
                if (mem_we) begin
                    repeat(2) @(posedge clk);
                    mem_ready = 1;
                end else begin
                    repeat(4) @(posedge clk);
                    mem_data = {mem_addr[31:0] + 32'd4, mem_addr[31:0]};
                    mem_ready = 1;
                end
            end else if (mem_ready) begin
                mem_ready = 0;
            end
        end
    end

    task execute_access(input [31:0] a, input [31:0] d, input w, input r, input is_i, output [31:0] r_d);
    begin
        @(negedge clk);
        addr = a;
        wr_data = d;
        we = w;
        re = r;
        is_instr = is_i;
        #1;
        if (stall) begin
            wait(stall == 0);
        end
        @(negedge clk);
        r_d = rd_data;
        we = 0;
        re = 0;
    end
    endtask

    reg [31:0] data_out;

    initial begin
        $display("---10: Full Cache Subsystem Integration Test ---");
        clk = 0;
        rst = 1;
        addr = 0;
        wr_data = 0;
        we = 0;
        re = 0;
        is_instr = 0;
        
        #15;
        rst = 0;
        
        // 1. Instruction Fetch (Miss -> L2 -> Mem)
        $display("[%0t] Fetching Instruction at 0x1000", $time);
        execute_access(32'h00001000, 0, 0, 1, 1, data_out);
        $display("Fetched: %h", data_out);
        if (data_out !== 32'h00001000) $display("FAIL: I-Fetch returned wrong data");
        
        // 2. Data Read (Miss -> L2 -> Mem)
        $display("[%0t] Reading Data at 0x2000", $time);
        execute_access(32'h00002000, 0, 0, 1, 0, data_out);
        $display("Read: %h", data_out);
        if (data_out !== 32'h00002000) $display("FAIL: D-Read returned wrong data");

        // 3. Data Write (Hit L1 -> WT -> L2 D$ -> Mem)
        $display("[%0t] Writing Data to 0x2000", $time);
        execute_access(32'h00002000, 32'hCAFEBABE, 1, 0, 0, data_out);
        $display("Write complete");
        
        // 4. Data Read (Hit L1)
        $display("[%0t] Reading Data at 0x2000", $time);
        execute_access(32'h00002000, 0, 0, 1, 0, data_out);
        $display("Read: %h", data_out);
        if (data_out !== 32'hCAFEBABE) $display("FAIL: D-Read returned wrong data after write");
        
        $display("Test finished.");
        $finish;
    end

endmodule
