`include "defines.vh"

/*
 * Module: alu_int
 * Description: Integer ALU for RISC-V. Selects operation via funct3/funct7/opcode.
 *              Supports RV32I base + load/store address calc.
 */
module alu_int (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [6:0]  opcode,
    input  wire [2:0]  funct3,
    input  wire [6:0]  funct7,
    output reg  [31:0] result,
    output wire        N,
    output wire        Z,
    output reg         C,
    output reg         V
);

    // ---- Sub-module outputs ----
    wire [31:0] add_res, sub_res;
    wire [31:0] bitwise_res, shift_res;
    wire        add_cout, add_ovf;
    wire        sub_borrow, sub_ovf;
    wire        shift_cout;

    cla_32bit adder (
        .a(a), .b(b), .cin(1'b0), .sum(add_res), .cout(add_cout), .overflow(add_ovf)
    );

    sub_32bit subtractor (
        .a(a), .b(b), .diff(sub_res), .borrow(sub_borrow), .overflow(sub_ovf)
    );

    // Bitwise unit op mapping: 000=AND, 001=OR, 010=XOR, 011=NOT, 100=NOR
    reg [2:0] bw_op;
    always @(*) begin
        case (funct3)
            `F3_AND:     bw_op = 3'b000;
            `F3_OR:      bw_op = 3'b001;
            `F3_XOR:     bw_op = 3'b010;
            default:     bw_op = 3'b000;
        endcase
    end

    bitwise_unit bitwise (
        .a(a), .b(b), .op(bw_op), .result(bitwise_res)
    );

    // Shift type: 00=SLL, 01=SRL, 10=SRA
    reg [1:0] shift_type;
    always @(*) begin
        case (funct3)
            `F3_SLL:     shift_type = 2'b00;
            `F3_SRL_SRA: shift_type = (funct7[5]) ? 2'b10 : 2'b01; // SRA vs SRL
            default:     shift_type = 2'b00;
        endcase
    end

    barrel_shifter shifter (
        .a(a), .shamt(b[4:0]), .shift_type(shift_type),
        .result(shift_res), .carry_out(shift_cout)
    );

    // Signed/unsigned comparisons for SLT/SLTU
    wire slt_result  = ($signed(a) < $signed(b)) ? 1'b1 : 1'b0;
    wire sltu_result = (a < b) ? 1'b1 : 1'b0;

    // ---- Determine if this is a SUB (R-type with funct7[5]=1, funct3=000) ----
    wire is_r_type = (opcode == `OPC_OP);
    wire is_sub    = is_r_type && (funct3 == `F3_ADD_SUB) && (funct7[5] == 1'b1);

    // ---- Output Mux ----
    always @(*) begin
        result = 32'd0;
        C = 1'b0;
        V = 1'b0;

        // Load/Store: base + offset (always ADD)
        if (opcode == `OPC_LOAD || opcode == `OPC_STORE || opcode == `OPC_JALR) begin
            result = add_res;
            C = add_cout;
            V = add_ovf;
        end
        // LUI: pass immediate through
        else if (opcode == `OPC_LUI || opcode == `OPC_AUIPC) begin
            result = b;  // imm32 (already shifted by imm_extender)
        end
        // R-type or I-type ALU
        else begin
            case (funct3)
                `F3_ADD_SUB: begin
                    if (is_sub) begin
                        result = sub_res;
                        C = sub_borrow;
                        V = sub_ovf;
                    end else begin
                        result = add_res;
                        C = add_cout;
                        V = add_ovf;
                    end
                end
                `F3_SLL: begin
                    result = shift_res;
                    C = shift_cout;
                end
                `F3_SLT: begin
                    result = {31'd0, slt_result};
                end
                `F3_SLTU: begin
                    result = {31'd0, sltu_result};
                end
                `F3_XOR: begin
                    result = bitwise_res;
                end
                `F3_SRL_SRA: begin
                    result = shift_res;
                    C = shift_cout;
                end
                `F3_OR: begin
                    result = bitwise_res;
                end
                `F3_AND: begin
                    result = bitwise_res;
                end
                default: begin
                    result = 32'd0;
                end
            endcase
        end
    end

    // N and Z flags based on final result
    assign N = result[31];
    assign Z = (result == 32'd0);

endmodule
