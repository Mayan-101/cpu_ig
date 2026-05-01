# Opcode & Encoding Table
**CPU:** Custom 32-bit RISC | **Opcode width:** 6 bits (64 slots)

---

## Opcode Space Allocation

| Range | Group | Count |
|---|---|---|
| 0x00–0x0F | Integer Register-Register (R-type) | 16 |
| 0x10–0x1B | Integer Immediate (I-type) | 12 |
| 0x1C–0x1F | Reserved | 4 |
| 0x20–0x27 | Load / Store (I-type) | 8 |
| 0x28–0x2E | Floating Point (R-type) | 7 |
| 0x2F | Reserved | 1 |
| 0x30–0x37 | Branch (I-type) | 8 |
| 0x38–0x3C | Jump / Call / Return (J and I-type) | 5 |
| 0x3D–0x3E | I/O (I-type) | 2 |
| 0x3F | MISC (R-type, funct-decoded) | 1 |
| **Total used** | | **52 + 12 MISC sub-ops** |

---

## Group 1: Integer Register-Register (R-type, opcode 0x00–0x0F)

> Format: `MNEMONIC rd, rs1, rs2`  
> funct field = 0x00 unless noted. Future-proofing: full funct field reserved per opcode.

| Opcode | Mnemonic | Operation | Flags updated | Notes |
|---|---|---|---|---|
| 0x00 | NOP | no operation | — | `rd=rs1=rs2=funct=0` canonical |
| 0x01 | ADD | `rd = rs1 + rs2` | N, Z, C, V | signed addition |
| 0x02 | SUB | `rd = rs1 - rs2` | N, Z, C, V | rs1 − rs2 |
| 0x03 | AND | `rd = rs1 & rs2` | N, Z | bitwise AND |
| 0x04 | OR  | `rd = rs1 \| rs2` | N, Z | bitwise OR |
| 0x05 | XOR | `rd = rs1 ^ rs2` | N, Z | bitwise XOR |
| 0x06 | NOT | `rd = ~rs1` | N, Z | bitwise NOT; rs2 ignored |
| 0x07 | SLL | `rd = rs1 << rs2[4:0]` | N, Z, C | logical left shift |
| 0x08 | SRL | `rd = rs1 >> rs2[4:0]` | N, Z, C | logical right shift (zero fill) |
| 0x09 | SRA | `rd = rs1 >>> rs2[4:0]` | N, Z | arithmetic right shift (sign fill) |
| 0x0A | ROR | `rd = ror(rs1, rs2[4:0])` | N, Z, C | rotate right |
| 0x0B | MUL | `rd = (rs1 × rs2)[31:0]` | Z | lower 32 bits; multi-cycle |
| 0x0C | MULH | `rd = (rs1 × rs2)[63:32]` | Z | upper 32 bits; multi-cycle |
| 0x0D | DIV | `rd = rs1 / rs2` (quotient) | Z | non-restoring; multi-cycle |
| 0x0E | MOD | `rd = rs1 % rs2` (remainder) | Z | same hardware as DIV |
| 0x0F | CMP | `flags ← rs1 − rs2; rd unchanged` | N, Z, C, V | compare only, no writeback |

> **Multi-cycle ops (MUL, MULH, DIV, MOD):** EX stage stalls the pipeline and asserts `mul_start` / `div_start`. Pipeline resumes when `done` goes high.  
> **MUL + MULH:** Both use the same 16-cycle Booth multiplier. Programmer uses consecutive MUL/MULH to get the full 64-bit product.

---

## Group 2: Integer Immediate (I-type, opcode 0x10–0x1B)

> Format: `MNEMONIC rd, rs1, imm14`  
> imm14 sign-extended to 32 bits unless noted.

| Opcode | Mnemonic | Operation | Flags | Notes |
|---|---|---|---|---|
| 0x10 | ADDI | `rd = rs1 + sext(imm14)` | N, Z, C, V | |
| 0x11 | SUBI | `rd = rs1 - sext(imm14)` | N, Z, C, V | |
| 0x12 | ANDI | `rd = rs1 & zext(imm14)` | N, Z | zero-extend |
| 0x13 | ORI  | `rd = rs1 \| zext(imm14)` | N, Z | zero-extend |
| 0x14 | XORI | `rd = rs1 ^ zext(imm14)` | N, Z | zero-extend |
| 0x15 | SLLI | `rd = rs1 << imm14[4:0]` | N, Z, C | |
| 0x16 | SRLI | `rd = rs1 >> imm14[4:0]` | N, Z, C | logical |
| 0x17 | SRAI | `rd = rs1 >>> imm14[4:0]` | N, Z | arithmetic |
| 0x18 | CMPI | `flags ← rs1 - sext(imm14)` | N, Z, C, V | no writeback |
| 0x19 | MOVI | `rd = sext(imm14)` | — | rs1 ignored; load small constant |
| 0x1A | LUI  | `rd = {imm20, 12'b0}` | — | **L-type format**; rs1 ignored |
| 0x1B | ADDC | `rd = rs1 + sext(imm14) + PSW[C]` | N, Z, C, V | add with carry |
| 0x1C–0x1F | — | Reserved | — | |

> **32-bit constant loading pattern:**
> ```asm
> LUI  R3, 0xABCDE     ; R3 = 0xABCDE000
> ORI  R3, R3, 0xF12   ; R3 = 0xABCDEF12
> ```

---

## Group 3: Load / Store (I-type, opcode 0x20–0x27)

> Format:  
> - Load:  `MNEMONIC rd, imm14(rs1)` → `rd = MEM[rs1 + sext(imm14)]`  
> - Store: `MNEMONIC rd, imm14(rs1)` → `MEM[rs1 + sext(imm14)] = rd`
>   (rd field is the *source* register for stores)

| Opcode | Mnemonic | Width | Operation | Signed? |
|---|---|---|---|---|
| 0x20 | LW  | 32-bit | `rd = MEM32[rs1 + sext(imm14)]` | sign-ext |
| 0x21 | SW  | 32-bit | `MEM32[rs1 + sext(imm14)] = rd` | — |
| 0x22 | LB  | 8-bit  | `rd = sext(MEM8[rs1 + sext(imm14)])` | signed |
| 0x23 | SB  | 8-bit  | `MEM8[rs1 + sext(imm14)] = rd[7:0]` | — |
| 0x24 | LH  | 16-bit | `rd = sext(MEM16[rs1 + sext(imm14)])` | signed |
| 0x25 | SH  | 16-bit | `MEM16[rs1 + sext(imm14)] = rd[15:0]` | — |
| 0x26 | LBU | 8-bit  | `rd = zext(MEM8[rs1 + sext(imm14)])` | unsigned |
| 0x27 | LHU | 16-bit | `rd = zext(MEM16[rs1 + sext(imm14)])` | unsigned |

> All memory addresses are **byte addresses**. LW/SW require 4-byte alignment. LH/SH require 2-byte alignment. Misaligned access behaviour: **undefined** in v1.0 (trap reserved for v1.1).

---

## Group 4: Floating-Point (R-type, opcode 0x28–0x2E)

> Format: `MNEMONIC rd, rs1, rs2` (rd/rs1/rs2 are general-purpose registers holding IEEE 754 bit patterns)  
> funct=0x00 for all unless extended later.

| Opcode | Mnemonic | Operation | Flags | Notes |
|---|---|---|---|---|
| 0x28 | FADD | `rd = fp_add(rs1, rs2)` | FN, FZ, FV, FU | combinational |
| 0x29 | FSUB | `rd = fp_sub(rs1, rs2)` | FN, FZ, FV, FU | combinational |
| 0x2A | FMUL | `rd = fp_mul(rs1, rs2)` | FN, FZ, FV, FU | multi-cycle (Booth mantissa mul) |
| 0x2B | FCMP | `float_flags ← fp_sub(rs1,rs2)` | FN, FZ, FV | no writeback; rd ignored |
| 0x2C | ITOF | `rd = int_to_float(rs1)` | — | rs2 ignored |
| 0x2D | FTOI | `rd = float_to_int(rs1)` | N, Z | truncates; rs2 ignored |
| 0x2E | FMOV | `rd = rs1` | — | register copy; rs2 ignored |
| 0x2F | — | Reserved | — | |

> **Float flags (in PSW[27:25]):**
> - FN: float result negative
> - FZ: float result zero
> - FV: float overflow (result = ±INF)
> - FU: float underflow (result = ±0 due to magnitude)
>
> **Special value handling:**
> - NaN input → NaN output (propagate)
> - INF ± INF → NaN (invalid)
> - ÷0 reserved for future; not in v1.0 float set

---

## Group 5: Branch (I-type, opcode 0x30–0x37)

> Format: `MNEMONIC rd, rs1, imm14`  
> Branch target: `PC + 4 + sext(imm14) << 2`  
> (imm14 is a signed count of *instructions*, ×4 for bytes)  
> Range: ±8191 instructions (±32764 bytes) from current PC

| Opcode | Mnemonic | Condition | Notes |
|---|---|---|---|
| 0x30 | BEQ  | `rd == rs1` | |
| 0x31 | BNE  | `rd != rs1` | |
| 0x32 | BLT  | `rd < rs1` (signed) | |
| 0x33 | BGT  | `rd > rs1` (signed) | |
| 0x34 | BLE  | `rd <= rs1` (signed) | |
| 0x35 | BGE  | `rd >= rs1` (signed) | |
| 0x36 | BLTU | `rd < rs1` (unsigned) | |
| 0x37 | BGEU | `rd >= rs1` (unsigned) | |

> Branch condition evaluated in **EX stage**.  
> If taken: PC ← branch_target; flush IF and ID stages (2-cycle penalty).

---

## Group 6: Jump / Call / Return (opcode 0x38–0x3C)

| Opcode | Mnemonic | Format | Operation | Notes |
|---|---|---|---|---|
| 0x38 | JAL  | J | `ACC = PC+4; PC = {PC[31:28], target26, 2'b00}` | Jump and link; saves return addr in ACC |
| 0x39 | JALR | I | `ACC = PC+4; PC = rs1 + sext(imm14)` | Indirect jump and link |
| 0x3A | CALL | J | `MEM[SP]=PC+4; SP-=4; PC = {PC[31:28],target26,2'b00}` | Hardware call; uses stack |
| 0x3B | RET  | R | `SP+=4; PC = MEM[SP]` | Return from CALL |
| 0x3C | RETI | R | `SP+=4; PC=MEM[SP]; SP+=4; PSW=MEM[SP]` | Return from interrupt (restores PSW) |

> **SP (Stack Pointer):** Dedicated internal register (not in the 34-register file). Accessible via `MOVSP` MISC instruction. Grows downward. Initial value = 0x0000107C (top of RAM).

---

## Group 7: I/O (I-type, opcode 0x3D–0x3E)

> Format:  
> - `IN  rd, imm14`  → `rd = IO[ zext(imm14) ]`  (read from I/O port)  
> - `OUT imm14, rs1` → `IO[ zext(imm14) ] = rs1[7:0]` (write to 8-bit SFR)  
> Access I/O space — completely separate from memory address space.

| Opcode | Mnemonic | Format | Operation | Notes |
|---|---|---|---|---|
| 0x3D | IN  | I | `rd = IO_space[ zext(imm14) ]` | rd=dest; rs1 ignored |
| 0x3E | OUT | I | `IO_space[ zext(imm14) ] = rs1[7:0]` | rd field ignored |

> **IN** zero-extends the 8-bit I/O port value to 32 bits in rd.  
> **OUT** writes only the low 8 bits of rs1 to the port (SFRs are 8-bit).  
> I/O address range: 0x0000–0x00FF (8-bit address, 256 ports).

---

## Group 8: MISC (R-type, opcode 0x3F, funct-decoded)

> Format: `R-type` with `opcode=0x3F`; operation determined by `funct[7:0]`

| funct | Mnemonic | Format | Operation | Notes |
|---|---|---|---|---|
| 0x00 | HLT    | — | Halt CPU execution | rd/rs1/rs2 = 0 |
| 0x01 | PUSH   | R | `MEM[SP]=rd; SP-=4` | Decrements SP first |
| 0x02 | POP    | R | `SP+=4; rd=MEM[SP]` | Increments SP first |
| 0x03 | MOVSP  | R | `SP = rs1` | Set stack pointer |
| 0x04 | GETSP  | R | `rd = SP` | Read stack pointer |
| 0x05 | SETB   | R | `rd = rd \| (1 << rs2[4:0])` | Set bit position rs2[4:0] in rd |
| 0x06 | CLRB   | R | `rd = rd & ~(1 << rs2[4:0])` | Clear bit |
| 0x07 | TESTB  | R | `Z = ~rd[rs2[4:0]]` | Test bit; sets Z flag only |
| 0x08 | SEI    | — | `PSW[IE] = 1` | Enable global interrupts |
| 0x09 | CLI    | — | `PSW[IE] = 0` | Disable global interrupts |
| 0x0A | ADDC   | R | `rd = rs1 + rs2 + PSW[C]` | Add with carry |
| 0x0B | SUBC   | R | `rd = rs1 - rs2 - PSW[C]` | Sub with borrow |
| 0x0C | SWAP   | R | `rd = {rs1[7:0],rs1[15:8],rs1[23:16],rs1[31:24]}` | Byte-swap (endian flip) |
| 0x0D | MOV    | R | `rd = rs1` | Register copy |
| 0x0E–0xFF | — | — | Reserved | |

---

## Instruction Count Summary

| Category | Count |
|---|---|
| Integer R-R | 16 |
| Integer Immediate | 12 |
| Load / Store | 8 |
| Float | 7 |
| Branch | 8 |
| Jump/Call/Return | 5 |
| I/O | 2 |
| MISC (sub-ops) | 14 |
| **Total** | **72 operations** |

---

## Assembly Syntax Reference

```
; R-type:  MNEM rd, rs1, rs2
ADD   R1, R2, R3          ; R1 = R2 + R3

; I-type:  MNEM rd, rs1, #imm   (ALU immediate)
ADDI  R1, R2, #100        ; R1 = R2 + 100

; I-type:  MNEM rd, #imm(rs1)   (memory)
LW    R4, #8(R5)          ; R4 = MEM[R5 + 8]
SW    R4, #8(R5)          ; MEM[R5 + 8] = R4

; I-type:  MNEM rd, rs1, #imm   (branch: rd vs rs1)
BEQ   R1, R2, #-3         ; if R1==R2: PC -= 8 (3 instrs back)

; J-type:  MNEM target_label
JAL   my_function         ; ACC = PC+4; jump to label

; L-type:  MNEM rd, #imm20
LUI   R1, #0xABCDE        ; R1 = 0xABCDE000

; I/O:
IN    R1, #0x80           ; R1 = P0 port value
OUT   #0x90, R2           ; P1 = R2[7:0]

; MISC (assembler expands):
PUSH  R3                  ; encodes as opcode=0x3F, funct=0x01, rd=R3
POP   R3                  ; encodes as opcode=0x3F, funct=0x02, rd=R3
HLT                       ; encodes as 0x3F000000 (funct=0x00)
SETB  R1, R2              ; bit R2[4:0] of R1 set
```

---

## Encoding Uniqueness Check

```
No two instructions share (opcode, funct) pair:
- Opcodes 0x00–0x3E: funct is don't-care (ignored or 0x00)
- Opcode 0x3F: funct selects among 14 sub-operations (0x00–0x0D)
Total unique encodings: 63 (opcodes 0x00–0x3E) + 14 (MISC sub-ops) = 77
Reserved opcodes: 0x1C–0x1F (4), 0x2F (1) — available for ISA v1.1
```
