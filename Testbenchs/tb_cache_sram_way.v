`timescale 1ns / 1ps

module tb_cache_sram_way;

    reg clk;
    reg [0:0] index;
    reg [27:0] wr_tag;
    reg [63:0] wr_data;
    reg we;

    wire [27:0] rd_tag;
    wire [63:0] rd_data;
    wire valid;
    wire dirty;

    cache_sram_way #(
        .INDEX_WIDTH(1),
        .TAG_WIDTH(28),
        .DATA_WIDTH(64)
    ) dut (
        .clk(clk),
        .index(index),
        .wr_tag(wr_tag),
        .wr_data(wr_data),
        .we(we),
        .rd_tag(rd_tag),
        .rd_data(rd_data),
        .valid(valid),
        .dirty(dirty)
    );

    always #5 clk = ~clk;

    initial begin
        $display("---2: Cache Line SRAM Model Test ---");
        clk = 0;
        we = 0;
        index = 0;
        wr_tag = 0;
        wr_data = 0;
        
        #10;
        // Test 1: Cold read
        index = 1'b0;
        #10;
        $display("Cold Read  -> Valid: %b, Dirty: %b, Tag: %x, Data: %x", valid, dirty, rd_tag, rd_data);
        if (valid !== 1'b0) $display("FAIL: Expected valid=0 on cold read.");
        
        // Test 2: Write
        @(negedge clk);
        we = 1'b1;
        wr_tag = 28'hA5A5A5A;
        wr_data = 64'hDEADBEEF_CAFEF00D;
        
        @(negedge clk);
        we = 1'b0;
        
        // Test 3: Read after write on same index
        #10;
        $display("After Write-> Valid: %b, Dirty: %b, Tag: %x, Data: %x", valid, dirty, rd_tag, rd_data);
        if (valid === 1'b1 && rd_tag === 28'hA5A5A5A && rd_data === 64'hDEADBEEF_CAFEF00D) begin
            $display("PASS: Valid bit set and data/tag match after write.");
        end else begin
            $display("FAIL: Write/Read mismatch.");
        end

        // Test 4: Cold read on another index
        index = 1'b1;
        #10;
        $display("Cold Read (index 1) -> Valid: %b", valid);
        if (valid !== 1'b0) $display("FAIL: Expected valid=0 on cold read index 1.");

        $finish;
    end

endmodule
