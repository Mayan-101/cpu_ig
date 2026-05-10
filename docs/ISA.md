# RISC-V Instruction Set Architecture (ISA)

The CPU has been migrated to the standard **RISC-V RV32I/M/F** Instruction Set Architecture. This ensures compatibility with standard compilers (e.g., `riscv32-unknown-elf-gcc`).

## Instruction Formats

Standard RISC-V 32-bit fixed-length encoding:

| Format | Structure | Usage |
| :--- | :--- | :--- |
| **R-Type** | `funct7(7), rs2(5), rs1(5), funct3(3), rd(5), opcode(7)` | Reg-Reg Arithmetic, RV32M, RV32F |
| **I-Type** | `imm[11:0], rs1(5), funct3(3), rd(5), opcode(7)` | Imm ALU, Loads, JALR |
| **S-Type** | `imm[11:5], rs2(5), rs1(5), funct3(3), imm[4:0], opcode(7)` | Stores |
| **B-Type** | `imm[12|10:5], rs2(5), rs1(5), funct3(3), imm[4:1|11], opcode(7)` | Branches |
| **U-Type** | `imm[31:12], rd(5), opcode(7)` | LUI, AUIPC |
| **J-Type** | `imm[20|10:1|11|19:12], rd(5), opcode(7)` | JAL |

## Registers

The CPU implements the standard RISC-V 32-register integer file (`x0`-`x31`).

| Register | Name | Description |
| :--- | :--- | :--- |
| `x0` | `zero` | Hardwired to 0 |
| `x1` | `ra` | Return address |
| `x2` | `sp` | Stack pointer |
| `x3` | `gp` | Global pointer |
| `x4` | `tp` | Thread pointer |
| `x5-x7` | `t0-t2` | Temporaries |
| `x8` | `s0`/`fp` | Saved register / Frame pointer |
| `x9` | `s1` | Saved register |
| `x10-x11`| `a0-a1` | Function arguments / Return values |
| `x12-x17`| `a2-a7` | Function arguments |
| `x18-x27`| `s2-s11`| Saved registers |
| `x28-x31`| `t3-t6` | Temporaries |

> [!NOTE]
> The custom `acc` (x32) and `b` (x33) registers have been deprecated. Use the general-purpose registers x0-x31.

## Instruction List

### RV32I Base Integer Instructions
- **Arithmetic**: `ADD`, `ADDI`, `SUB`, `LUI`, `AUIPC`
- **Logical**: `AND`, `ANDI`, `OR`, `ORI`, `XOR`, `XORI`
- **Shifts**: `SLL`, `SLLI`, `SRL`, `SRLI`, `SRA`, `SRAI`
- **Comparisons**: `SLT`, `SLTI`, `SLTU`, `SLTIU`
- **Jumps**: `JAL`, `JALR`
- **Branches**: `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`
- **Memory**: `LW`, `LH`, `LB`, `LHU`, `LBU`, `SW`, `SH`, `SB`

### RV32M Standard Extension (Multiplication/Division)
- `MUL`, `MULH`, `MULHSU`, `MULHU`
- `DIV`, `DIVU`, `REM`, `REMU`

### RV32F Standard Extension (Single-Precision Floating Point)
- `FADD.S`, `FSUB.S`, `FMUL.S`, `FDIV.S` (Hardware divider)
- `FMIN.S`, `FMAX.S`, `FSQRT.S`
- `FEQ.S`, `FLT.S`, `FLE.S`
- `FCVT.W.S`, `FCVT.S.W` (Conversion)
- `FMV.X.W`, `FMV.W.X` (Move between X and F registers)

### Custom Extensions (Opcode: `custom-0` / `0001011`)
Proprietary instructions are mapped to the standard RISC-V `custom-0` space to maintain toolchain compatibility.

| Instruction | Funct3 | Description |
| :--- | :--- | :--- |
| `HLT` | `000` | Halt CPU execution |
| `SEI` | `001` | Enable Interrupts (Global) |
| `CLI` | `010` | Disable Interrupts (Global) |
| `RETI` | `011` | Return from Interrupt |
| `IN` | `100` | Read from I/O port |
| `OUT` | `101` | Write to I/O port |

## Memory Map

| Range | Name | Description |
| :--- | :--- | :--- |
| `0x0000_0000 - 0x0000_3FFF` | ITCM | Instruction TCM (16 KB) |
| `0x0001_0000 - 0x0001_1FFF` | DTCM | Data TCM (8 KB) |
| `0x1000_0000 - 0x10FF_FFFF` | Main RAM | External/Main Memory (16 MB) |
| `0x4000_0000 - 0x4FFF_FFFF` | Peripheral | I/O Device Space |
| `0x8000_0000 - 0x8000_0FFF` | System | CSR and System Control |
