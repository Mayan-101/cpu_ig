`timescale 1ns / 1ps

module cla_16bit (
    input  wire [15:0] a,
    input  wire [15:0] b,
    input  wire        cin,
    output wire [15:0] sum,
    output wire        group_G,
    output wire        group_P,
    output wire        cout,
    output wire        overflow
);

    // Group Generate and Propagate from the 4-bit blocks
    wire [3:0] gg, gp;
    // Carries between the 4-bit blocks
    wire [4:0] c;

    assign c[0] = cin;

    //  Second-Level Lookahead Logic 
    // These equations are identical in structure to the 4-bit CLA carries, 
    // but they use Group G/P instead of bit-level g/p.
    assign c[1] = gg[0] | (gp[0] & c[0]);
    assign c[2] = gg[1] | (gp[1] & gg[0]) | (gp[1] & gp[0] & c[0]);
    assign c[3] = gg[2] | (gp[2] & gg[1]) | (gp[2] & gp[1] & gg[0]) | (gp[2] & gp[1] & gp[0] & c[0]);
    assign c[4] = gg[3] | (gp[3] & gg[2]) | (gp[3] & gp[2] & gg[1]) | (gp[3] & gp[2] & gp[1] & gg[0]) | (gp[3] & gp[2] & gp[1] & gp[0] & c[0]);

    // Instantiate 4 CLA4 blocks
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : cla4_blocks
            cla_4bit block (
                .a(a[4*i+3 : 4*i]),
                .b(b[4*i+3 : 4*i]),
                .cin(c[i]),
                .sum(sum[4*i+3 : 4*i]),
                .group_G(gg[i]),
                .group_P(gp[i]),
                .cout() // We use the LCU's c[i+1] instead of the ripple cout
            );
        end
    endgenerate

    // 16-bit block signals
    assign group_P = &gp; // All 4 blocks must propagate
    assign group_G = gg[3] | (gp[3] & gg[2]) | (gp[3] & gp[2] & gg[1]) | (gp[3] & gp[2] & gp[1] & gg[0]);
    assign cout    = c[4];
    
    // Signed Overflow: (A_msb == B_msb) AND (Sum_msb != A_msb)
    assign overflow = (a[15] == b[15]) && (sum[15] != a[15]);

endmodule
