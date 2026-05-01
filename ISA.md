# ISA Instruction Format Specification
**CPU:** Custom 32-bit RISC | **Instruction width:** 32-bit fixed

---

## Design Constraints

| Constraint | Value | Consequence |
|---|---|---|
| Word width | 32 bits | All instructions exactly 32 bits |
| Register count | 34 | Need 6-bit register fields (2⁶=64 ≥ 34) |
| Opcode width | 6 bits | 64 possible base opcodes |
| Addressing modes | imm / reg-direct / reg-indirect / base+offset | I-type covers all 4 |

---

## Instruction Formats

### R-Type — Register-Register Operations

```
 31      26 25    20 19    14 13     8 7        0
┌──────────┬────────┬────────┬────────┬──────────┐
│  opcode  │   rd   │  rs1   │  rs2   │  funct   │
│  [31:26] │[25:20] │[19:14] │[13:8]  │  [7:0]   │
│  6 bits  │ 6 bits │ 6 bits │ 6 bits │  8 bits  │
└──────────┴────────┴────────┴────────┴──────────┘
```

| Field | Bits | Width | Purpose |
|---|---|---|---|
| opcode | [31:26] | 6 | Instruction class |
| rd | [25:20] | 6 | Destination register (0–33) |
| rs1 | [19:14] | 6 | Source register 1 (0–33) |
| rs2 | [13:8] | 6 | Source register 2 (0–33) |
| funct | [7:0] | 8 | Sub-operation selector |

**Used by:** All register-register ALU ops, float ops, MISC (HLT/PUSH/POP/SETB/CLRB), RET, RETI  
**Addressing mode covered:** Register-direct

---

### I-Type — Immediate / Memory / Branch / I/O Operations

```
 31      26 25    20 19    14 13              0
┌──────────┬────────┬────────┬────────────────┐
│  opcode  │   rd   │  rs1   │     imm14      │
│  [31:26] │[25:20] │[19:14] │    [13:0]      │
│  6 bits  │ 6 bits │ 6 bits │    14 bits     │
└──────────┴────────┴────────┴────────────────┘
```

| Field | Bits | Width | Purpose |
|---|---|---|---|
| opcode | [31:26] | 6 | Instruction class |
| rd | [25:20] | 6 | Destination reg (loads/ALU-imm) OR source data reg (stores) |
| rs1 | [19:14] | 6 | Base register (memory), source reg (ALU-imm), compare reg (branches) |
| imm14 | [13:0] | 14 | Immediate value — interpretation depends on instruction |

**Immediate interpretation rules:**

| Instruction class | imm14 treatment |
|---|---|
| ALU immediate (ADDI, SUBI, etc.) | Sign-extended to 32 bits |
| Load / Store (LW, SW, LB…) | Sign-extended → byte offset |
| Branch (BEQ, BNE…) | Sign-extended, then shifted left 2 → byte offset from PC+4 |
| IN / OUT | Zero-extended → 16-bit I/O port address |
| MOVI | Sign-extended to 32 bits |

**Used by:** All immediate ALU, all loads/stores, all branches, IN, OUT, JALR  
**Addressing modes covered:** Immediate, register-indirect (imm14=0), base+offset

---

### J-Type — Unconditional Jump / Call

```
 31      26 25                               0
┌──────────┬──────────────────────────────────┐
│  opcode  │             target26             │
│  [31:26] │             [25:0]               │
│  6 bits  │             26 bits              │
└──────────┴──────────────────────────────────┘
```

| Field | Bits | Width | Purpose |
|---|---|---|---|
| opcode | [31:26] | 6 | Instruction class |
| target26 | [25:0] | 26 | Jump target — shifted left 2 to form 28-bit byte offset |

**Target address computation:**
```
jump_addr = { PC[31:28], target26, 2'b00 }
```
This gives a 30-bit range within the current 256MB page of PC.

**Used by:** JAL, CALL

---

### L-Type — Load Upper Immediate (LUI only)

```
 31      26 25    20 19                      0
┌──────────┬────────┬──────────────────────────┐
│  opcode  │   rd   │         imm20            │
│  [31:26] │[25:20] │         [19:0]           │
│  6 bits  │ 6 bits │         20 bits          │
└──────────┴────────┴──────────────────────────┘
```

**Operation:** `rd = { imm20, 12'b0 }` (places imm20 into bits [31:12])

**Use case — loading a 32-bit constant (two-instruction sequence):**
```asm
LUI   R1, val[31:12]      ; R1 = val[31:12] << 12  (bits 31:12 set)
ORI   R1, R1, val[11:0]   ; R1 = R1 | val[11:0]   (bits 11:0 set)
```
> Note: ORI uses a 14-bit immediate (zero-extended), so val[11:0] always fits.

---

## Format Summary Table

| Format | Used for | rd role | imm bits | Range |
|---|---|---|---|---|
| R | Reg-reg ALU, float, MISC | destination | — | — |
| I | Imm ALU, mem, branch, I/O | dest or store-src | 14 signed | ±8191 |
| J | JAL, CALL | — | 26 (×4) | ±128MB |
| L | LUI only | destination | 20 (<<12) | upper 20 bits |

---

## Encoding Verification

```
R-type:  6 + 6 + 6 + 6 + 8  = 32 ✓
I-type:  6 + 6 + 6 + 14      = 32 ✓
J-type:  6 + 26               = 32 ✓
L-type:  6 + 6 + 20           = 32 ✓
```

---

## NOP Canonical Encoding

```
NOP = 0x00000000
    = R-type, opcode=0x00 (NOP), rd=R0, rs1=R0, rs2=R0, funct=0x00
```

All-zero word is a valid NOP. This is intentional so that uninitialized ROM locations are safe.
