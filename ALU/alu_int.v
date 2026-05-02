`timescale 1ns / 1ps

module alu_int (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [5:0]  alu_op,
    output reg  [31:0] result,
    output wire        N,
    output wire        Z,
    output reg         C,
    output reg         V
);

    // ALU Opcodes (Architecture Synchronized)
    localparam OP_ADD  = 6'h01;
    localparam OP_SUB  = 6'h02;
    localparam OP_AND  = 6'h03;
    localparam OP_OR   = 6'h04;
    localparam OP_XOR  = 6'h05;
    localparam OP_NOT  = 6'h06;
    localparam OP_LSL  = 6'h07;
    localparam OP_LSR  = 6'h08;
    localparam OP_ASR  = 6'h09;
    localparam OP_ROR  = 6'h0A;

    //  Module Outputs 
    wire [31:0] add_res, sub_res;
    wire [31:0] bitwise_res, shift_res;
    wire        add_cout;
    wire        add_ovf;
    wire        sub_borrow;
    wire        sub_ovf;
    wire        shift_cout;
    wire        cmp_eq, cmp_lt_s, cmp_gt_s, cmp_lt_u, cmp_gt_u;

    cla_32bit adder (
        .a(a), .b(b), .cin(1'b0), .sum(add_res), .cout(add_cout), .overflow(add_ovf)
    );

    sub_32bit subtractor (
        .a(a), .b(b), .diff(sub_res), .borrow(sub_borrow), .overflow(sub_ovf)
    );

    // Bitwise unit op mapping: 000=AND, 001=OR, 010=XOR, 011=NOT, 100=NOR
    reg [2:0] bw_op;
    always @(*) begin
        case (alu_op)
            OP_AND: bw_op = 3'b000;
            OP_OR:  bw_op = 3'b001;
            OP_XOR: bw_op = 3'b010;
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
            6'h01, 6'h10, 6'h1B, 6'h20, 6'h21, 6'h22, 6'h23, 6'h24, 6'h25: begin // ADD, ADDI, ADDC, Load/Store Addresses
                result = add_res;
                C = add_cout;
                V = add_ovf;
            end
            6'h02, 6'h11, 6'h0F, 6'h18: begin // SUB, SUBI, CMP, CMPI
                result = sub_res;
                C = sub_borrow;
                V = sub_ovf;
            end
            6'h03, 6'h12: begin // AND, ANDI
                result = a & b;
            end
            6'h04, 6'h13: begin // OR, ORI
                result = a | b;
            end
            6'h05, 6'h14: begin // XOR, XORI
                result = a ^ b;
            end
            6'h06: begin // NOT
                result = ~a;
            end
            6'h07, 6'h15: begin // SLL, SLLI
                result = shift_res;
                C = shift_cout;
            end
            6'h08, 6'h16: begin // SRL, SRLI
                result = shift_res;
                C = shift_cout;
            end
            6'h09, 6'h17: begin // SRA, SRAI
                result = shift_res;
            end
            6'h0A: begin // ROR
                result = shift_res;
                C = shift_cout;
            end
            6'h19, 6'h1A: begin // MOVI, LUI
                result = b;
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
