`include "defines.vh"

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
            `OP_AND, `OP_ANDI: bw_op = 3'b000;
            `OP_OR,  `OP_ORI:  bw_op = 3'b001;
            `OP_XOR, `OP_XORI: bw_op = 3'b010;
            `OP_NOT:           bw_op = 3'b011;
            default:           bw_op = 3'b000;
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
            `OP_LSL, `OP_LSLI: shift_type = 2'b00;
            `OP_LSR, `OP_LSRI: shift_type = 2'b01;
            `OP_ASR, `OP_ASRI: shift_type = 2'b10;
            `OP_ROR:           shift_type = 2'b11;
            default:           shift_type = 2'b00;
        endcase
    end

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
            `OP_ADD, `OP_ADDI, `OP_ADDC, `OP_LW, `OP_SW, `OP_LH, `OP_SH, `OP_LB, `OP_SB, `OP_LBU, `OP_LHU: begin
                result = add_res;
                C = add_cout;
                V = add_ovf;
            end
            `OP_SUB, `OP_SUBI, `OP_CMP, `OP_CMPI: begin
                result = sub_res;
                C = sub_borrow;
                V = sub_ovf;
            end
            `OP_AND, `OP_ANDI, `OP_OR, `OP_ORI, `OP_XOR, `OP_XORI, `OP_NOT: begin
                result = bitwise_res;
            end
            `OP_LSL, `OP_LSLI, `OP_LSR, `OP_LSRI, `OP_ROR: begin
                result = shift_res;
                C = shift_cout;
            end
            `OP_ASR, `OP_ASRI: begin
                result = shift_res;
            end
            `OP_MOVI, `OP_LUI: begin
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
