# Instruction Set Architecture (ISA)

The CPU implements a custom 32-bit RISC ISA with support for Integer and Floating-Point operations.

## Instruction Formats

| Format | Structure | Usage |
| :--- | :--- | :--- |
| **R-Type** | `opcode(6), rd(6), rs1(6), rs2(6), funct(8)` | Arithmetic/Logic, FPU |
| **I-Type** | `opcode(6), rd(6), rs1(6), imm(14)` | Immediate ALU, JALR |
| **B-Type** | `opcode(6), rs2(6), rs1(6), imm(14)` | Conditional Branches |
| **J-Type** | `opcode(6), imm(26)` | Jumps, Calls |
| **M-Type** | `opcode(6), rd(6), rs1(6), imm(14)` | Memory Load/Store |
| **L-Type** | `opcode(6), rd(6), imm(20)` | Load Upper Immediate |
| **IO-Type**| `opcode(6), rd(6), 0(6), port(14)` | I/O Operations |

## Registers

| Register | Name | Description |
| :--- | :--- | :--- |
| `x0` | `zero` | Constant 0 |
| `x1` | `ra` | Return Address (RISC-V ABI) |
| `x2` | `sp` | Stack Pointer (RISC-V ABI) |
| `x3-x31` | `gp` | General Purpose Registers |
| `x32` | `acc` | Accumulator |
| `x33` | `b` | Auxiliary Arithmetic Register |

## Instruction List

### Integer Arithmetic (Group 1 & 2)
- `ADD`, `SUB`, `AND`, `OR`, `XOR`, `NOT`
- `ADDI`, `SUBI`, `ANDI`, `ORI`, `XORI`
- `MUL`, `MULH`, `DIV`, `MOD`
- `SLL`, `SRL`, `SRA`, `ROR`
- `SLLI`, `SRLI`, `SRAI`
- `CMP`, `CMPI` (Sets comparison flags)

### Floating Point (Group 4)
- `FADD`, `FSUB`, `FMUL`
- `FCMP` (Floating point comparison)
- `ITOF` (Integer to Float conversion)
- `FTOI` (Float to Integer conversion)
- `FMOV` (Move between FP registers)

### Memory Operations (Group 3)
- `LW` (0x20), `SW` (0x21) (Word 32-bit)
- `LH` (0x22), `SH` (0x23) (Half-word 16-bit)
- `LB` (0x24), `SB` (0x25) (Byte 8-bit)
- `LBU` (0x26), `LHU` (0x27) (Unsigned variants)

### Control Flow (Group 5 & 6)
- `BEQ`, `BNE`, `BLT`, `BGT`, `BLE`, `BGE`
- `JAL`, `JALR`, `CALL`, `RET`, `RETI`

### I/O Operations (Group 7)
- `IN` (0x3D), `OUT` (0x3E)

### System (Group 8)
- `HLT` (Halt CPU)
- `SEI`, `CLI` (Interrupt control: Enable/Disable)
