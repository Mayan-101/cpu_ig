`ifndef DEFINES_VH
`define DEFINES_VH

// ALU Opcodes
`define OP_ADD      6'h01
`define OP_SUB      6'h02
`define OP_AND      6'h03
`define OP_OR       6'h04
`define OP_XOR      6'h05
`define OP_NOT      6'h06
`define OP_LSL      6'h07
`define OP_LSR      6'h08
`define OP_ASR      6'h09
`define OP_ROR      6'h0A
`define OP_MUL      6'h0B
`define OP_MULH     6'h0C
`define OP_DIV      6'h0D
`define OP_MOD      6'h0E
`define OP_CMP      6'h0F

// I-Type ALU Opcodes (Arithmetic with Imm)
`define OP_ADDI     6'h10
`define OP_SUBI     6'h11
`define OP_ANDI     6'h12
`define OP_ORI      6'h13
`define OP_XORI     6'h14
`define OP_LSLI     6'h15
`define OP_LSRI     6'h16
`define OP_ASRI     6'h17
`define OP_CMPI     6'h18
`define OP_MOVI     6'h19
`define OP_LUI      6'h1A
`define OP_ADDC     6'h1B

// Load/Store Opcodes
`define OP_LW       6'h20
`define OP_SW       6'h21
`define OP_LH       6'h22
`define OP_SH       6'h23
`define OP_LB       6'h24
`define OP_SB       6'h25
`define OP_LBU      6'h26
`define OP_LHU      6'h27

// Floating Point Opcodes
`define OP_FADD     6'h28
`define OP_FSUB     6'h29
`define OP_FMUL     6'h2A
`define OP_FCMP     6'h2B
`define OP_ITOF     6'h2C
`define OP_FTOI     6'h2D
`define OP_FMOV     6'h2E

// Branch Opcodes
`define OP_BEQ      6'h30
`define OP_BNE      6'h31
`define OP_BLT      6'h32
`define OP_BGT      6'h33
`define OP_BLE      6'h34
`define OP_BGE      6'h35
`define OP_BLTU     6'h36
`define OP_BGEU     6'h37

// Jump Opcodes
`define OP_JAL      6'h38
`define OP_JALR     6'h39
`define OP_CALL     6'h3A
`define OP_RET      6'h3B
`define OP_RETI     6'h3C

// System Opcodes
`define OP_IN       6'h3D
`define OP_OUT      6'h3E
`define OP_MISC     6'h3F

// Special Register Indices
`define REG_ACC     6'd32
`define REG_B       6'd33

// Miscelaneous Function Codes
`define FUNCT_HALT  8'h00
`define FUNCT_NOP   8'h01
`define FUNCT_EI    8'h08
`define FUNCT_DI    8'h09

`endif
