`timescale 1ns / 1ps

module alu_int (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [4:0]  alu_op,
    output reg  [31:0] result,
    output wire        N,
    output wire        Z,
    output reg         C,
    output reg         V
);

    // ALU Opcodes
    localparam OP_ADD  = 5'b00000;
    localparam OP_SUB  = 5'b00001;
    localparam OP_AND  = 5'b00010;
    localparam OP_OR   = 5'b00011;
    localparam OP_XOR  = 5'b00100;
    localparam OP_NOR  = 5'b00101;
    localparam OP_LSL  = 5'b00110;
    localparam OP_LSR  = 5'b00111;
    localparam OP_ASR  = 5'b01000;
    localparam OP_ROR  = 5'b01001;
    localparam OP_SLT  = 5'b01010;
    localparam OP_SLTU = 5'b01011;

    //  Module Outputs 
    wire [31:0] add_res, sub_res, bitwise_res, shift_res;
    wire        add_cout, add_ovf;
    wire        sub_borrow, sub_ovf;
    wire        shift_cout;
    wire        cmp_eq, cmp_lt_s, cmp_gt_s, cmp_lt_u, cmp_gt_u;

    //  Instances 
    cla_32bit adder (
        .a(a),
        .b(b),
        .cin(1'b0),
        .sum(add_res),
        .cout(add_cout),
        .overflow(add_ovf)
    );

    sub_32bit subtractor (
        .a(a),
        .b(b),
        .diff(sub_res),
        .borrow(sub_borrow),
        .overflow(sub_ovf)
    );

    // Bitwise unit op mapping: 000=AND, 001=OR, 010=XOR, 011=NOT, 100=NOR
    reg [2:0] bw_op;
    always @(*) begin
        case (alu_op)
            OP_AND: bw_op = 3'b000;
            OP_OR:  bw_op = 3'b001;
            OP_XOR: bw_op = 3'b010;
            OP_NOR: bw_op = 3'b100;
            default: bw_op = 3'b000;
        endcase
    end

    bitwise_unit bitwise (
        .a(a),
        .b(b),
        .op(bw_op),
        .result(bitwise_res)
    );

    // Shift type: 00=LSL, 01=LSR, 10=ASR, 11=ROR
    reg [1:0] shift_type;
    always @(*) begin
        case (alu_op)
            OP_LSL: shift_type = 2'b00;
            OP_LSR: shift_type = 2'b01;
            OP_ASR: shift_type = 2'b10;
            OP_ROR: shift_type = 2'b11;
            default: shift_type = 2'b00;
        endcase
    end

    // Assuming b[4:0] is used for shamt if a is shifted by b, or a is shift amount? 
    // Wait, usually rs1 (a) is shifted by rs2 (b). So a is input, b[4:0] is shamt.
    barrel_shifter shifter (
        .a(a),
        .shamt(b[4:0]),
        .shift_type(shift_type),
        .result(shift_res),
        .carry_out(shift_cout)
    );

    comparator_unit cmp_s (
        .a(a),
        .b(b),
        .signed_mode(1'b1),
        .eq(cmp_eq),
        .lt(cmp_lt_s),
        .gt(cmp_gt_s)
    );

    comparator_unit cmp_u (
        .a(a),
        .b(b),
        .signed_mode(1'b0),
        .eq(),
        .lt(cmp_lt_u),
        .gt(cmp_gt_u)
    );

    //  Output Mux and Flags 
    always @(*) begin
        // Defaults
        result = 32'd0;
        C = 1'b0;
        V = 1'b0;

        case (alu_op)
            OP_ADD: begin
                result = add_res;
                C = add_cout;
                V = add_ovf;
            end
            OP_SUB: begin
                result = sub_res;
                C = sub_borrow; // For borrow
                V = sub_ovf;
            end
            OP_AND, OP_OR, OP_XOR, OP_NOR: begin
                result = bitwise_res;
            end
            OP_LSL, OP_LSR, OP_ASR, OP_ROR: begin
                result = shift_res;
                C = shift_cout;
            end
            OP_SLT: begin
                result = {31'd0, cmp_lt_s};
                C = sub_borrow;
                V = sub_ovf;
            end
            OP_SLTU: begin
                result = {31'd0, cmp_lt_u};
                C = sub_borrow;
            end
            default: begin
                result = 32'd0;
            end
        endcase
    end

    // N and Z flags based on final result
    assign N = result[31];
    assign Z = (result == 32'd0);

endmodule
