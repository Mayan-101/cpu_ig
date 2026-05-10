`timescale 1ns / 1ps

module tb_addr_decomp;

    reg [31:0] addr_in;
    
    wire [27:0] l1_tag;
    wire [0:0]  l1_index;
    wire [2:0]  l1_offset;
    
    addr_decomp #(
        .ADDR_WIDTH(32),
        .LINE_SIZE(8),
        .NUM_SETS(2)
    ) l1_decomp (
        .addr(addr_in),
        .tag(l1_tag),
        .index(l1_index),
        .block_offset(l1_offset)
    );

    wire [28:0] l2_tag;
    wire [0:0]  l2_index;
    wire [2:0]  l2_offset;
    
    // L2 (2 sets x 4 ways, 8B/line)
    addr_decomp #(
        .ADDR_WIDTH(32),
        .LINE_SIZE(8),
        .NUM_SETS(2)
    ) l2_decomp (
        .addr(addr_in),
        .tag(l2_tag),
        .index(l2_index),
        .block_offset(l2_offset)
    );

    initial begin
        $display("---1: Address Decomposition Test ---");
        
        addr_in = 32'hA5A5_A5A5;
        #10;
        $display("ADDR: %h", addr_in);
        $display("L1 -> Tag: %x, Index: %b, Offset: %b", l1_tag, l1_index, l1_offset);
        $display("L2 -> Tag: %x, Index: %b, Offset: %b", l2_tag, l2_index, l2_offset);
        
        addr_in = 32'h0000_0008; // L1: offset=0, index=1, tag=0
        #10;
        $display("\nADDR: %h", addr_in);
        $display("L1 -> Tag: %x, Index: %b, Offset: %b", l1_tag, l1_index, l1_offset);
        
        addr_in = 32'hFFFF_FFF8; // L1: offset=0, index=1, tag=FFFFFFF
        #10;
        $display("ADDR: %h", addr_in);
        $display("L1 -> Tag: %x, Index: %b, Offset: %b", l1_tag, l1_index, l1_offset);

        if (l1_index === 1'b1 && l1_offset === 3'b000) begin
            $display("PASS: Two addresses differing only in tag map to same index.");
        end else begin
            $display("FAIL: Tag/index split error.");
        end
        
        $finish;
    end

endmodule
