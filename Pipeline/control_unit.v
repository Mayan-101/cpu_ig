`include "defines.vh"

/*
 * Module: control_unit
 * Description: Combinational control logic. Decodes opcode/funct fields 
 *              into pipeline control signals and ALU operation codes.
 */
module control_unit (
    input  wire [5:0] opcode,
    input  wire [7:0] funct,
    
    output reg  [5:0] alu_op,
    output reg        mem_read,
    output reg        mem_write,
    output reg        reg_write,
    output reg        branch,
    output reg        jump,
    output reg        is_float,
    output reg        is_io,
    output reg  [1:0] wb_src,   // 0: ALU, 1: MEM, 2: PC+4 (ACC), 3: IO
    output reg        alu_src,  // 0: RS2, 1: IMM
    output reg  [1:0] ext_mode, // 0: SIGN, 1: ZERO, 2: JUMP, 3: LUI
    output reg        is_reti,
    output reg        is_halt   // Added explicit halt output control
);

    always @(*) begin
        //  Default Control State 
        alu_op    = opcode;
        mem_read  = 0;
        mem_write = 0;
        reg_write = 0;
        branch    = 0;
        jump      = 0;
        is_float  = 0;
        is_io     = 0;
        wb_src    = 2'b00;
        alu_src   = 0;
        ext_mode  = 2'b00; // Default SIGN extension
        is_reti   = 0;
        is_halt   = 0;

        case (opcode[5:4])
            //  Group 1: R-type Instructions (0x00 - 0x0F) 
            2'b00: begin
                if (opcode != 6'h00 && opcode != 6'h0F) begin
                    reg_write = 1;
                end
            end

            //  Group 2: I-type ALU Instructions (0x10 - 0x1B) 
            2'b01: begin
                alu_src = 1;
                if (opcode != `OP_CMPI) reg_write = 1; // CMPI does not write back
                
                if (opcode == `OP_ANDI || opcode == `OP_ORI || opcode == `OP_XORI) begin
                    ext_mode = 2'b01; // Logical instructions use ZERO extension
                end else if (opcode == `OP_LUI) begin
                    ext_mode = 2'b11; // LUI mode
                end
            end

            //  Group 3/4: Load/Store and Floating Point (0x20 - 0x2E) 
            2'b10: begin
                if (opcode[3] == 0) begin // Load / Store
                    alu_src = 1;
                    if (opcode == `OP_LW || opcode == `OP_LH || opcode == `OP_LB || opcode == `OP_LBU || opcode == `OP_LHU) begin
                        mem_read  = 1;
                        reg_write = 1;
                        wb_src    = 2'b01; // MEM source
                    end else if (opcode == `OP_SW || opcode == `OP_SH || opcode == `OP_SB) begin
                        mem_write = 1;
                    end
                end else begin // Floating Point
                    is_float = 1;
                    if (opcode != `OP_FCMP && opcode != `OP_FMOV) reg_write = 1; // Corrected FCMP/FMOV logic
                end
            end

            //  Group 5/6/7/8: Branch, Jump, I/O, and MISC (0x30 - 0x3F) 
            2'b11: begin
                if (opcode[3] == 0) begin // Branching
                    branch = 1;
                end else begin
                    if (opcode >= `OP_JAL && opcode <= `OP_CALL) begin // Jump / Call
                        jump = 1;
                        if (opcode == `OP_JAL || opcode == `OP_CALL) ext_mode = 2'b10; // JUMP mode
                        if (opcode == `OP_RETI) is_reti = 1;
                    end else if (opcode == `OP_IN || opcode == `OP_OUT) begin // I/O
                        is_io    = 1;
                        alu_src  = 1;
                        ext_mode = 2'b01; 
                        if (opcode == `OP_IN) begin // IN instruction
                            reg_write = 1;
                            wb_src    = 2'b11; 
                        end
                    end else if (opcode == `OP_MISC) begin // MISC instructions
                        // Decode HALT operation
                        if (funct == `FUNCT_HALT) is_halt = 1;
                    end
                end
            end
            default: ;
        endcase
    end

endmodule
