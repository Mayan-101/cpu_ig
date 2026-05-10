`timescale 1ns / 1ps

module tb_cache_core_4way;

    reg clk;
    reg rst;
    reg [31:0] addr;
    reg [63:0] wr_data;
    reg we;
    reg re;

    wire [63:0] rd_data;
    wire hit;
    wire [1:0] evict_way;
    wire [63:0] evict_data;

    localparam INDEX_WIDTH = 1;
    localparam TAG_WIDTH = 28;
    localparam DATA_WIDTH = 64;

    cache_core #(
        .INDEX_WIDTH(INDEX_WIDTH),
        .TAG_WIDTH(TAG_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .WAYS(4)
    ) dut (
        .clk(clk),
        .rst(rst),
        .addr(addr),
        .wr_data(wr_data),
        .we(we),
        .re(re),
        .rd_data(rd_data),
        .hit(hit),
        .evict_way(evict_way),
        .evict_data(evict_data)
    );

    always #5 clk = ~clk;

    // Helper task to write to cache (simulate a line fill)
    task fill_line(input [31:0] a, input [63:0] d);
    begin
        @(negedge clk);
        addr = a;
        wr_data = d;
        we = 1;
        re = 0;
        @(negedge clk);
        we = 0;
    end
    endtask

    // Helper task to read from cache
    task read_cache(input [31:0] a, output h);
    begin
        @(negedge clk);
        addr = a;
        re = 1;
        we = 0;
        #1;
        h = hit;
        @(negedge clk);
        re = 0;
    end
    endtask

    reg h_res;

    initial begin
        $display("---5: 4-Way Set-Associative Cache Core Test ---");
        clk = 0;
        rst = 1;
        addr = 0;
        wr_data = 0;
        we = 0;
        re = 0;
        
        #15;
        rst = 0;

        // All addresses map to index 0 (addr[3] = 0)
        // addr = tag << 4
        // Tags: 1, 2, 3, 4, 5
        
        // Sequential fill of 4 ways
        fill_line(32'h00000010, 64'hAAAA); // Tag 1
        fill_line(32'h00000020, 64'hBBBB); // Tag 2
        fill_line(32'h00000030, 64'hCCCC); // Tag 3
        fill_line(32'h00000040, 64'hDDDD); // Tag 4

        // Hit on each way (0,1,2,3 -> LRU becomes way 0 again)
        read_cache(32'h00000010, h_res);
        if (!h_res) $display("FAIL: Expected hit on Tag 1");
        
        read_cache(32'h00000020, h_res);
        if (!h_res) $display("FAIL: Expected hit on Tag 2");

        read_cache(32'h00000030, h_res);
        if (!h_res) $display("FAIL: Expected hit on Tag 3");

        read_cache(32'h00000040, h_res);
        if (!h_res) $display("FAIL: Expected hit on Tag 4");

        // 5th unique access -> evicts LRU way (way 0)
        // Let's do a read first to check miss and evict_way
        @(negedge clk);
        addr = 32'h00000050; // Tag 5
        re = 1;
        #1;
        $display("Access Tag 5 -> Hit: %b, Evict Way: %d, Evict Data: %h", hit, evict_way, evict_data);
        if (hit !== 0 || evict_way !== 0) $display("FAIL: Expected miss and evict_way=0.");
        
        @(negedge clk);
        re = 0;
        
        // Fill Tag 5 (will write to way 0)
        fill_line(32'h00000050, 64'hEEEE);

        // Access way 0 address again (Tag 1) -> miss
        read_cache(32'h00000010, h_res);
        $display("Access Tag 1 (Evicted) -> Hit: %b", h_res);
        if (h_res !== 0) $display("FAIL: Expected miss on Tag 1.");

        // Other 3 addresses still hit
        read_cache(32'h00000020, h_res);
        if (!h_res) $display("FAIL: Expected hit on Tag 2");
        
        read_cache(32'h00000030, h_res);
        if (!h_res) $display("FAIL: Expected hit on Tag 3");
        
        read_cache(32'h00000040, h_res);
        if (!h_res) $display("FAIL: Expected hit on Tag 4");

        read_cache(32'h00000050, h_res);
        if (!h_res) $display("FAIL: Expected hit on Tag 5");

        $finish;
    end

endmodule
