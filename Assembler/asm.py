def encode_r(op, rd, rs1, rs2, funct=0):
    return (op << 26) | (rd << 20) | (rs1 << 14) | (rs2 << 8) | funct

def encode_i(op, rd, rs1, imm):
    return (op << 26) | (rd << 20) | (rs1 << 14) | (imm & 0x3FFF)

def encode_l(op, rd, imm20):
    return (op << 26) | (rd << 20) | (imm20 & 0xFFFFF)

def encode_b(op, rs1, rs2, offset):
    return (op << 26) | (rs2 << 20) | (rs1 << 14) | (offset & 0x3FFF)

# Register Map
# x1:base, x2:B_ptr, x3:C_ptr, x4:cnt, x10:1, x11:10, x12:valA, x13:valB, x5:tmpA, x6:tmpB, x7:sum
# Ops: LUI=26, ADDI=16, ADD=1, SW=33, LW=32, BNE=49, HLT=63

prog = [
    encode_l(26, 1, 0x20000),        # 0: LUI x1, 0x20000 (RAM start)
    encode_i(16, 2, 1, 20),          # 1: ADDI x2, x1, 20 (Array B start)
    encode_i(16, 3, 1, 40),          # 2: ADDI x3, x1, 40 (Array C start)
    encode_i(16, 4, 0, 5),           # 3: ADDI x4, x0, 5  (Count)
    encode_i(16, 10, 0, 1),          # 4: ADDI x10, x0, 1 (Inc A)
    encode_i(16, 11, 0, 10),         # 5: ADDI x11, x0, 10 (Inc B)
    encode_i(16, 12, 0, 0),          # 6: ADDI x12, x0, 0 (Val A accumulator)
    encode_i(16, 13, 0, 0),          # 7: ADDI x13, x0, 0 (Val B accumulator)
    
    # Loop Init RAM (8-15)
    encode_r(1, 12, 12, 10),         # 8: ADD x12, x12, x10
    encode_i(33, 12, 1, 0),          # 9: SW x12, 0(x1)
    encode_r(1, 13, 13, 11),         # 10: ADD x13, x13, x11
    encode_i(33, 13, 2, 0),          # 11: SW x13, 0(x2)
    encode_i(16, 1, 1, 4),           # 12: ADDI x1, x1, 4
    encode_i(16, 2, 2, 4),           # 13: ADDI x2, x2, 4
    encode_i(16, 4, 4, -1),          # 14: ADDI x4, x4, -1
    encode_b(49, 4, 0, -8),          # 15: BNE x4, x0, -8 
    
    # Reset Pointers (16-19)
    encode_l(26, 1, 0x20000),        # 16: LUI x1, 0x20000
    encode_i(16, 2, 1, 20),          # 17: ADDI x2, x1, 20
    encode_i(16, 3, 1, 40),          # 18: ADDI x3, x1, 40
    encode_i(16, 4, 0, 5),           # 19: ADDI x4, x0, 5
    
    # Loop Add (20-28)
    encode_i(32, 5, 1, 0),           # 20: LW x5, 0(x1)
    encode_i(32, 6, 2, 0),           # 21: LW x6, 0(x2)
    encode_r(1, 7, 5, 6),            # 22: ADD x7, x5, x6
    encode_i(33, 7, 3, 0),           # 23: SW x7, 0(x3)
    encode_i(16, 1, 1, 4),           # 24: ADDI x1, x1, 4
    encode_i(16, 2, 2, 4),           # 25: ADDI x2, x2, 4
    encode_i(16, 3, 3, 4),           # 26: ADDI x3, x3, 4
    encode_i(16, 4, 4, -1),          # 27: ADDI x4, x4, -1
    encode_b(49, 4, 0, -9),          # 28: BNE x4, x0, -9 
    
    encode_r(0x3F, 0, 0, 0, funct=0x00) # 29: HLT - Fixed format to match hardware FUNCT_HALT
]

# Pad to 1024 words
while len(prog) < 1024:
    prog.append(0)

with open("rom_init.mem", "w") as f:
    for instr in prog:
        f.write(f"{instr:08x}\n")

print(f"Assembled {len(prog)} words to rom_init.mem")