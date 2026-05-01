`timescale 1ns / 1ps

module cla_4bit (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire       cin,
    output wire [3:0] sum,
    output wire       group_G,
    output wire       group_P,
    output wire       cout
);

    // Internal wires for bit-level Generate (g) and Propagate (p)
    wire [3:0] g;
    wire [3:0] p;
    
    // Internal wire array for the parallel carries
    wire [4:0] c; 

    // Step 1: Compute bit-level Generate and Propagate
    assign g = a & b; // Generate: gi = ai * bi
    assign p = a ^ b; // Propagate: pi = ai XOR bi (XOR is used so we can reuse it for sum)

    // Step 2: Compute parallel carries
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);

    // Step 3: Compute Block/Group Generate and Propagate
    assign group_P = p[3] & p[2] & p[1] & p[0];
    assign group_G = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);

    // Step 4: Final outputs
    assign sum  = p ^ c[3:0]; 
    assign cout = c[4]; // Can also be represented as: group_G | (group_P & cin)

endmodule