`timescale 1ns / 1ps

module float_norm (
    input  wire [47:0] raw_mant,   
    input  wire [8:0]  raw_exp,    
    output reg  [7:0]  final_exp,
    output reg  [22:0] final_mant,
    output reg         done_uf,    
    output reg         done_of     
);

    integer i;
    reg [5:0] l_one;
    reg found;

    always @(*) begin
        l_one = 0;
        found = 0;
        for (i = 47; i >= 0; i = i - 1) begin
            if (raw_mant[i] && !found) begin
                l_one = i;
                found = 1;
            end
        end

        // Fix: Explicitly handle INF and NaN exponents coming in
        if (raw_exp >= 9'd255) begin
            final_exp = 8'hFF;
            final_mant = 23'h0;
            done_of = 1;
            done_uf = 0;
        end else if (!found) begin
            final_exp = 0; final_mant = 0; done_uf = 0; done_of = 0;
        end else begin
            // Normalization logic
            if (l_one >= 23) begin
                final_exp = raw_exp + (l_one - 23);
                final_mant = (raw_mant >> (l_one - 23));
            end else begin
                if (raw_exp < (23 - l_one)) begin
                    final_exp = 0; final_mant = 0; done_uf = 1;
                end else begin
                    final_exp = raw_exp - (23 - l_one);
                    final_mant = (raw_mant << (23 - l_one));
                end
            end
            
            done_of = (final_exp >= 255);
            if (done_of) begin
                final_exp = 8'hFF;
                final_mant = 23'h0;
            end
        end
    end
endmodule
