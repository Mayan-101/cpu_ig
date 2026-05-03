`timescale 1ns / 1ps

module tb_bitwise_unit;

    reg [31:0] a, b;
    reg [2:0]  op;
    wire [31:0] result;

    bitwise_unit uut (
        .a(a), .b(b), .op(op), .result(result)
    );

    integer i, j;
    reg [31:0] test_vals [0:3];
    reg [8*5:1] op_name;

    initial begin
        test_vals[0] = 32'h00000000;
        test_vals[1] = 32'hFFFFFFFF;
        test_vals[2] = 32'hA5A5A5A5;
        test_vals[3] = 32'h5A5A5A5A;

        $display("Starting Bitwise Unit Tests...");
        $display("---------------------------------------------------------");
        $display(" Op   | Input A  | Input B  | Result   ");
        $display("---------------------------------------------------------");

        for (i = 0; i < 4; i = i + 1) begin
            a = test_vals[i];
            b = ~test_vals[i]; // Using complement for B to see distinct results

            for (j = 0; j < 7; j = j + 1) begin
                op = j;
                case(op)
                    3'b000: op_name = "AND ";
                    3'b001: op_name = "OR  ";
                    3'b010: op_name = "XOR ";
                    3'b011: op_name = "NOT ";
                    3'b100: op_name = "NOR ";
                    3'b101: op_name = "NAND";
                    3'b110: op_name = "XNOR";
                endcase
                
                #10;
                $display(" %s | %h | %h | %h ", op_name, a, b, result);
            end
            $display("---------------------------------------------------------");
        end
        $finish;
    end

endmodule
