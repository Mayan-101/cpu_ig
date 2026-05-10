`ifndef DEFINES_VH
`define DEFINES_VH

// ============================================================================
//  RISC-V RV32I/M/F Standard Opcode Map
//  Encoding: instruction[6:0] = opcode
//            instruction[14:12] = funct3
//            instruction[31:25] = funct7
//  GCC-compatible: riscv32-unknown-elf-gcc output runs directly on this CPU.
// ============================================================================

// --- Major Opcodes (instruction[6:0]) ---
`define OPC_OP        7'b0110011   // R-type: register-register ALU (ADD, SUB, AND, OR, ...)
`define OPC_OP_IMM    7'b0010011   // I-type: register-immediate ALU (ADDI, ANDI, ORI, ...)
`define OPC_LOAD      7'b0000011   // I-type: loads (LB, LH, LW, LBU, LHU)
`define OPC_STORE     7'b0100011   // S-type: stores (SB, SH, SW)
`define OPC_BRANCH    7'b1100011   // B-type: conditional branches (BEQ, BNE, BLT, BGE, ...)
`define OPC_JAL       7'b1101111   // J-type: jump and link
`define OPC_JALR      7'b1100111   // I-type: jump and link register
`define OPC_LUI       7'b0110111   // U-type: load upper immediate
`define OPC_AUIPC     7'b0010111   // U-type: add upper immediate to PC
`define OPC_SYSTEM    7'b1110011   // I-type: system (ECALL, EBREAK, CSR*)
`define OPC_OP_FP     7'b1010011   // R-type: floating-point operations
`define OPC_CUSTOM0   7'b0001011   // Custom-0: HLT, SEI, CLI, IN, OUT, RETI

// --- funct3 for R-type / I-type ALU (OPC_OP / OPC_OP_IMM) ---
`define F3_ADD_SUB  3'b000   // ADD (funct7=0x00) / SUB (funct7=0x20)
`define F3_SLL      3'b001   // Shift Left Logical
`define F3_SLT      3'b010   // Set Less Than (signed)
`define F3_SLTU     3'b011   // Set Less Than Unsigned
`define F3_XOR      3'b100   // XOR
`define F3_SRL_SRA  3'b101   // SRL (funct7=0x00) / SRA (funct7=0x20)
`define F3_OR       3'b110   // OR
`define F3_AND      3'b111   // AND

// --- funct7 for R-type ALU ---
`define F7_BASE     7'b0000000   // ADD, SLL, SLT, SLTU, XOR, SRL, OR, AND
`define F7_ALT      7'b0100000   // SUB, SRA
`define F7_MULDIV   7'b0000001   // RV32M: MUL, MULH, DIV, REM

// --- funct3 for RV32M (Multiply/Divide, OPC_OP with F7_MULDIV) ---
`define F3_MUL      3'b000
`define F3_MULH     3'b001
`define F3_MULHSU   3'b010
`define F3_MULHU    3'b011
`define F3_DIV      3'b100
`define F3_DIVU     3'b101
`define F3_REM      3'b110
`define F3_REMU     3'b111

// --- funct3 for LOAD (OPC_LOAD) ---
`define F3_LB       3'b000
`define F3_LH       3'b001
`define F3_LW       3'b010
`define F3_LBU      3'b100
`define F3_LHU      3'b101

// --- funct3 for STORE (OPC_STORE) ---
`define F3_SB       3'b000
`define F3_SH       3'b001
`define F3_SW       3'b010

// --- funct3 for BRANCH (OPC_BRANCH) ---
`define F3_BEQ      3'b000
`define F3_BNE      3'b001
`define F3_BLT      3'b100
`define F3_BGE      3'b101
`define F3_BLTU     3'b110
`define F3_BGEU     3'b111

// --- funct3 for JALR (OPC_JALR) ---
`define F3_JALR     3'b000

// --- funct7/funct3 for Floating Point (OPC_OP_FP) ---
`define F7_FADD     7'b0000000
`define F7_FSUB     7'b0000100
`define F7_FMUL     7'b0001000
`define F7_FCMP     7'b1010000   // FEQ/FLT/FLE
`define F7_ITOF     7'b1101000   // FCVT.S.W
`define F7_FTOI     7'b1100000   // FCVT.W.S
`define F7_FMOV_XW  7'b1111000   // FMV.W.X (int → float reg)
`define F7_FMOV_WX  7'b1110000   // FMV.X.W (float reg → int)

// --- funct3 for CUSTOM-0 (OPC_CUSTOM0) ---
`define F3_HLT      3'b000
`define F3_SEI      3'b001
`define F3_CLI      3'b010
`define F3_RETI     3'b011
`define F3_IN       3'b100
`define F3_OUT      3'b101

// --- SYSTEM funct3 ---
`define F3_ECALL    3'b000   // ECALL/EBREAK (distinguished by imm[11:0])

// --- Immediate constants for ECALL/EBREAK ---
`define IMM_ECALL   12'b000000000000
`define IMM_EBREAK  12'b000000000001

`endif
