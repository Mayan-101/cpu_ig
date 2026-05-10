import sys
import re

# =============================================================================
#  RISC-V RV32I/M/F Assembler
#  Produces machine code compatible with riscv32-unknown-elf-gcc output.
#  Custom extensions: HLT, SEI, CLI, RETI, IN, OUT  (CUSTOM-0 opcode space)
# =============================================================================

# --- Standard RISC-V Opcodes (bits [6:0]) ---
OPC_OP      = 0b0110011   # R-type ALU
OPC_OP_IMM  = 0b0010011   # I-type ALU
OPC_LOAD    = 0b0000011   # I-type Load
OPC_STORE   = 0b0100011   # S-type Store
OPC_BRANCH  = 0b1100011   # B-type Branch
OPC_JAL     = 0b1101111   # J-type JAL
OPC_JALR    = 0b1100111   # I-type JALR
OPC_LUI     = 0b0110111   # U-type LUI
OPC_AUIPC   = 0b0010111   # U-type AUIPC
OPC_SYSTEM  = 0b1110011   # System (ECALL/EBREAK)
OPC_OP_FP   = 0b1010011   # R-type Float
OPC_CUSTOM0 = 0b0001011   # Custom-0

# Instruction table: mnemonic -> (format, opcode, funct3, funct7)
# Format codes: 'R', 'I', 'S', 'B', 'U', 'J', 'CUSTOM', 'PSEUDO', 'SYSTEM'
INSTRUCTIONS = {
    # --- R-type ALU (OPC_OP) ---
    'ADD':    ('R', OPC_OP, 0b000, 0b0000000),
    'SUB':    ('R', OPC_OP, 0b000, 0b0100000),
    'SLL':    ('R', OPC_OP, 0b001, 0b0000000),
    'SLT':    ('R', OPC_OP, 0b010, 0b0000000),
    'SLTU':   ('R', OPC_OP, 0b011, 0b0000000),
    'XOR':    ('R', OPC_OP, 0b100, 0b0000000),
    'SRL':    ('R', OPC_OP, 0b101, 0b0000000),
    'SRA':    ('R', OPC_OP, 0b101, 0b0100000),
    'OR':     ('R', OPC_OP, 0b110, 0b0000000),
    'AND':    ('R', OPC_OP, 0b111, 0b0000000),

    # --- RV32M (Multiply/Divide, OPC_OP with funct7=0x01) ---
    'MUL':    ('R', OPC_OP, 0b000, 0b0000001),
    'MULH':   ('R', OPC_OP, 0b001, 0b0000001),
    'MULHSU': ('R', OPC_OP, 0b010, 0b0000001),
    'MULHU':  ('R', OPC_OP, 0b011, 0b0000001),
    'DIV':    ('R', OPC_OP, 0b100, 0b0000001),
    'DIVU':   ('R', OPC_OP, 0b101, 0b0000001),
    'REM':    ('R', OPC_OP, 0b110, 0b0000001),
    'REMU':   ('R', OPC_OP, 0b111, 0b0000001),

    # --- I-type ALU (OPC_OP_IMM) ---
    'ADDI':   ('I', OPC_OP_IMM, 0b000, None),
    'SLTI':   ('I', OPC_OP_IMM, 0b010, None),
    'SLTIU':  ('I', OPC_OP_IMM, 0b011, None),
    'XORI':   ('I', OPC_OP_IMM, 0b100, None),
    'ORI':    ('I', OPC_OP_IMM, 0b110, None),
    'ANDI':   ('I', OPC_OP_IMM, 0b111, None),
    'SLLI':   ('ISHIFT', OPC_OP_IMM, 0b001, 0b0000000),
    'SRLI':   ('ISHIFT', OPC_OP_IMM, 0b101, 0b0000000),
    'SRAI':   ('ISHIFT', OPC_OP_IMM, 0b101, 0b0100000),

    # --- Load (OPC_LOAD) ---
    'LB':     ('LOAD', OPC_LOAD, 0b000, None),
    'LH':     ('LOAD', OPC_LOAD, 0b001, None),
    'LW':     ('LOAD', OPC_LOAD, 0b010, None),
    'LBU':    ('LOAD', OPC_LOAD, 0b100, None),
    'LHU':    ('LOAD', OPC_LOAD, 0b101, None),

    # --- Store (OPC_STORE) ---
    'SB':     ('S', OPC_STORE, 0b000, None),
    'SH':     ('S', OPC_STORE, 0b001, None),
    'SW':     ('S', OPC_STORE, 0b010, None),

    # --- Branch (OPC_BRANCH) ---
    'BEQ':    ('B', OPC_BRANCH, 0b000, None),
    'BNE':    ('B', OPC_BRANCH, 0b001, None),
    'BLT':    ('B', OPC_BRANCH, 0b100, None),
    'BGE':    ('B', OPC_BRANCH, 0b101, None),
    'BLTU':   ('B', OPC_BRANCH, 0b110, None),
    'BGEU':   ('B', OPC_BRANCH, 0b111, None),

    # --- JAL (OPC_JAL) ---
    'JAL':    ('J', OPC_JAL, None, None),

    # --- JALR (OPC_JALR) ---
    'JALR':   ('I', OPC_JALR, 0b000, None),

    # --- U-type ---
    'LUI':    ('U', OPC_LUI, None, None),
    'AUIPC':  ('U', OPC_AUIPC, None, None),

    # --- Floating Point (OPC_OP_FP) --- shared integer register file
    'FADD':   ('R', OPC_OP_FP, 0b000, 0b0000000),
    'FSUB':   ('R', OPC_OP_FP, 0b000, 0b0000100),
    'FMUL':   ('R', OPC_OP_FP, 0b000, 0b0001000),
    'FCMP':   ('R', OPC_OP_FP, 0b010, 0b1010000),  # FEQ.S equivalent
    'ITOF':   ('R', OPC_OP_FP, 0b000, 0b1101000),  # FCVT.S.W
    'FTOI':   ('R', OPC_OP_FP, 0b000, 0b1100000),  # FCVT.W.S

    # --- Custom-0 extensions ---
    'HLT':    ('CUSTOM', OPC_CUSTOM0, 0b000, None),
    'SEI':    ('CUSTOM', OPC_CUSTOM0, 0b001, None),
    'CLI':    ('CUSTOM', OPC_CUSTOM0, 0b010, None),
    'RETI':   ('CUSTOM', OPC_CUSTOM0, 0b011, None),
    'IN':     ('CUSTOM_IO', OPC_CUSTOM0, 0b100, None),
    'OUT':    ('CUSTOM_IO', OPC_CUSTOM0, 0b101, None),

    # --- System ---
    'ECALL':  ('SYSTEM', OPC_SYSTEM, 0b000, None),
    'EBREAK': ('SYSTEM', OPC_SYSTEM, 0b000, None),

    # --- Pseudo-instructions (expanded before encoding) ---
    'NOP':    ('PSEUDO', None, None, None),
    'MV':     ('PSEUDO', None, None, None),
    'NOT':    ('PSEUDO', None, None, None),
    'NEG':    ('PSEUDO', None, None, None),
    'RET':    ('PSEUDO', None, None, None),
    'CALL':   ('PSEUDO', None, None, None),
    'LI':     ('PSEUDO', None, None, None),
    'LA':     ('PSEUDO', None, None, None),
    'J':      ('PSEUDO', None, None, None),
    'SEQZ':   ('PSEUDO', None, None, None),
    'SNEZ':   ('PSEUDO', None, None, None),
    'BGT':    ('PSEUDO', None, None, None),
    'BLE':    ('PSEUDO', None, None, None),
    'BGTU':   ('PSEUDO', None, None, None),
    'BLEU':   ('PSEUDO', None, None, None),
    'FMOV':   ('PSEUDO', None, None, None),
    'MOD':    ('PSEUDO', None, None, None),
}

# RISC-V register map — standard ABI names
REGS = {f'x{i}': i for i in range(32)}
REGS.update({
    'zero': 0,  'ra': 1,   'sp': 2,   'gp': 3,   'tp': 4,
    'a0': 10, 'a1': 11, 'a2': 12, 'a3': 13, 'a4': 14, 'a5': 15, 'a6': 16, 'a7': 17,
    't0': 5,  't1': 6,  't2': 7,  't3': 28, 't4': 29, 't5': 30, 't6': 31,
    's0': 8,  'fp': 8,  's1': 9,
    's2': 18, 's3': 19, 's4': 20, 's5': 21, 's6': 22, 's7': 23,
    's8': 24, 's9': 25, 's10': 26, 's11': 27,
})


def parse_reg(reg_str):
    reg_str = reg_str.lower().strip().rstrip(',')
    if reg_str in REGS:
        return REGS[reg_str]
    if reg_str.startswith('x'):
        try:
            n = int(reg_str[1:])
            if 0 <= n < 32:
                return n
        except ValueError:
            pass
    raise ValueError(f"Invalid register: {reg_str}")


def parse_imm(imm_str):
    imm_str = imm_str.strip().strip('#').strip(',')
    if imm_str.startswith('0x') or imm_str.startswith('0X'):
        return int(imm_str, 16)
    if imm_str.startswith('0b') or imm_str.startswith('0B'):
        return int(imm_str, 2)
    return int(imm_str)


def sign_extend(value, bits):
    """Sign extend a value from `bits` width to Python int."""
    mask = (1 << bits) - 1
    value = value & mask
    if value & (1 << (bits - 1)):
        value -= (1 << bits)
    return value


def bits(value, nbits):
    """Mask value to nbits."""
    return value & ((1 << nbits) - 1)


# ---- RISC-V Instruction Encoders ----

def encode_r(opcode, rd, rs1, rs2, funct3, funct7):
    return (bits(funct7, 7) << 25) | (bits(rs2, 5) << 20) | (bits(rs1, 5) << 15) | \
           (bits(funct3, 3) << 12) | (bits(rd, 5) << 7) | bits(opcode, 7)


def encode_i(opcode, rd, rs1, imm, funct3):
    return (bits(imm, 12) << 20) | (bits(rs1, 5) << 15) | \
           (bits(funct3, 3) << 12) | (bits(rd, 5) << 7) | bits(opcode, 7)


def encode_s(opcode, rs1, rs2, imm, funct3):
    imm_val = bits(imm, 12)
    imm_11_5 = (imm_val >> 5) & 0x7F
    imm_4_0  = imm_val & 0x1F
    return (imm_11_5 << 25) | (bits(rs2, 5) << 20) | (bits(rs1, 5) << 15) | \
           (bits(funct3, 3) << 12) | (imm_4_0 << 7) | bits(opcode, 7)


def encode_b(opcode, rs1, rs2, imm, funct3):
    # imm is byte offset, must be even — bit 0 is not stored
    imm_val = bits(imm, 13)
    bit_12   = (imm_val >> 12) & 1
    bit_11   = (imm_val >> 11) & 1
    bit_10_5 = (imm_val >> 5) & 0x3F
    bit_4_1  = (imm_val >> 1) & 0xF
    return (bit_12 << 31) | (bit_10_5 << 25) | (bits(rs2, 5) << 20) | \
           (bits(rs1, 5) << 15) | (bits(funct3, 3) << 12) | \
           (bit_4_1 << 8) | (bit_11 << 7) | bits(opcode, 7)


def encode_u(opcode, rd, imm):
    # imm is the upper 20 bits (already shifted in source)
    return (bits(imm, 20) << 12) | (bits(rd, 5) << 7) | bits(opcode, 7)


def encode_j(opcode, rd, imm):
    # imm is byte offset; bit 0 is not stored
    imm_val  = bits(imm, 21)
    bit_20   = (imm_val >> 20) & 1
    bit_19_12= (imm_val >> 12) & 0xFF
    bit_11   = (imm_val >> 11) & 1
    bit_10_1 = (imm_val >> 1) & 0x3FF
    return (bit_20 << 31) | (bit_10_1 << 21) | (bit_11 << 20) | \
           (bit_19_12 << 12) | (bits(rd, 5) << 7) | bits(opcode, 7)


def expand_pseudo(mnemonic, args, current_pc, labels):
    """Expand a pseudo-instruction into one or more real instructions.
    Returns a list of (mnemonic, args) tuples."""
    if mnemonic == 'NOP':
        return [('ADDI', ['x0', 'x0', '0'])]
    elif mnemonic == 'MV':
        return [('ADDI', [args[0], args[1], '0'])]
    elif mnemonic == 'NOT':
        return [('XORI', [args[0], args[1], '-1'])]
    elif mnemonic == 'NEG':
        return [('SUB', [args[0], 'x0', args[1]])]
    elif mnemonic == 'RET':
        return [('JALR', ['x0', 'ra', '0'])]
    elif mnemonic == 'J':
        return [('JAL', ['x0', args[0]])]
    elif mnemonic == 'CALL':
        return [('JAL', ['ra', args[0]])]
    elif mnemonic == 'SEQZ':
        return [('SLTIU', [args[0], args[1], '1'])]
    elif mnemonic == 'SNEZ':
        return [('SLTU', [args[0], 'x0', args[1]])]
    elif mnemonic == 'BGT':
        # BGT rs, rt, offset  → BLT rt, rs, offset
        return [('BLT', [args[1], args[0], args[2]])]
    elif mnemonic == 'BLE':
        # BLE rs, rt, offset  → BGE rt, rs, offset
        return [('BGE', [args[1], args[0], args[2]])]
    elif mnemonic == 'BGTU':
        return [('BLTU', [args[1], args[0], args[2]])]
    elif mnemonic == 'BLEU':
        return [('BGEU', [args[1], args[0], args[2]])]
    elif mnemonic == 'FMOV':
        # FMOV rd, rs  → ADDI rd, rs, 0 (shared register file)
        return [('ADDI', [args[0], args[1], '0'])]
    elif mnemonic == 'MOD':
        # MOD rd, rs1, rs2  → REM rd, rs1, rs2
        return [('REM', [args[0], args[1], args[2]])]
    elif mnemonic == 'LI':
        imm = parse_imm(args[1])
        if -2048 <= imm <= 2047:
            return [('ADDI', [args[0], 'x0', str(imm)])]
        else:
            upper = (imm + 0x800) >> 12
            lower = imm - (upper << 12)
            result = [('LUI', [args[0], str(upper)])]
            if lower != 0:
                result.append(('ADDI', [args[0], args[0], str(lower)]))
            return result
    elif mnemonic == 'LA':
        # LA rd, symbol — for now treat as LI with label address
        target = args[1]
        if target in labels:
            addr = labels[target]
            upper = (addr + 0x800) >> 12
            lower = addr - (upper << 12)
            result = [('LUI', [args[0], str(upper)])]
            if lower != 0:
                result.append(('ADDI', [args[0], args[0], str(lower)]))
            return result
        raise ValueError(f"LA: undefined label: {target}")
    else:
        raise ValueError(f"Unknown pseudo-instruction: {mnemonic}")


def encode_instruction(mnemonic, args, current_pc, labels):
    """Encode a single real (non-pseudo) instruction to a 32-bit integer."""
    info = INSTRUCTIONS[mnemonic]
    fmt, opcode, funct3, funct7 = info

    if fmt == 'R':
        rd  = parse_reg(args[0])
        rs1 = parse_reg(args[1])
        rs2 = parse_reg(args[2]) if len(args) > 2 else 0
        return encode_r(opcode, rd, rs1, rs2, funct3, funct7)

    elif fmt == 'I':
        rd  = parse_reg(args[0])
        rs1 = parse_reg(args[1])
        imm = parse_imm(args[2])
        return encode_i(opcode, rd, rs1, imm, funct3)

    elif fmt == 'ISHIFT':
        rd  = parse_reg(args[0])
        rs1 = parse_reg(args[1])
        shamt = parse_imm(args[2]) & 0x1F
        imm12 = (funct7 << 5) | shamt
        return encode_i(opcode, rd, rs1, imm12, funct3)

    elif fmt == 'LOAD':
        rd = parse_reg(args[0])
        # Parse offset(base) syntax
        match = re.search(r'#?(-?\d+|0x[0-9a-fA-F]+)\s*\(\s*(\w+)\s*\)', args[1])
        if not match:
            raise ValueError(f"Invalid load operand: {args[1]}")
        imm = parse_imm(match.group(1))
        rs1 = parse_reg(match.group(2))
        return encode_i(opcode, rd, rs1, imm, funct3)

    elif fmt == 'S':
        rs2 = parse_reg(args[0])
        match = re.search(r'#?(-?\d+|0x[0-9a-fA-F]+)\s*\(\s*(\w+)\s*\)', args[1])
        if not match:
            raise ValueError(f"Invalid store operand: {args[1]}")
        imm = parse_imm(match.group(1))
        rs1 = parse_reg(match.group(2))
        return encode_s(opcode, rs1, rs2, imm, funct3)

    elif fmt == 'B':
        rs1 = parse_reg(args[0])
        rs2 = parse_reg(args[1])
        target = args[2]
        if target in labels:
            offset = labels[target] - current_pc  # byte offset
        else:
            offset = parse_imm(target)
        return encode_b(opcode, rs1, rs2, offset, funct3)

    elif fmt == 'J':
        # JAL rd, offset/label
        if len(args) == 2:
            rd = parse_reg(args[0])
            target = args[1]
        else:
            # JAL label (rd defaults to ra)
            rd = 1   # ra
            target = args[0]
        if target in labels:
            offset = labels[target] - current_pc
        else:
            offset = parse_imm(target)
        return encode_j(opcode, rd, offset)

    elif fmt == 'U':
        rd = parse_reg(args[0])
        imm = parse_imm(args[1])
        return encode_u(opcode, rd, imm)

    elif fmt == 'CUSTOM':
        # No operands: HLT, SEI, CLI, RETI
        # Encoded as: imm12=0, rs1=0, funct3, rd=0, opcode
        return encode_i(opcode, 0, 0, 0, funct3)

    elif fmt == 'CUSTOM_IO':
        # IN rd, port_imm  /  OUT rs2, port_imm
        rd_or_rs = parse_reg(args[0])
        imm = parse_imm(args[1])
        if mnemonic == 'IN':
            return encode_i(opcode, rd_or_rs, 0, imm, funct3)
        else:  # OUT
            return encode_s(opcode, 0, rd_or_rs, imm, funct3)

    elif fmt == 'SYSTEM':
        imm12 = 0x000 if mnemonic == 'ECALL' else 0x001
        return encode_i(opcode, 0, 0, imm12, funct3)

    raise ValueError(f"Unknown format: {fmt} for {mnemonic}")


def count_pseudo_words(mnemonic, args, labels):
    """Return the number of 32-bit words a pseudo-instruction expands to."""
    if mnemonic == 'LI':
        imm = parse_imm(args[1])
        if -2048 <= imm <= 2047:
            return 1
        else:
            upper = (imm + 0x800) >> 12
            lower = imm - (upper << 12)
            return 1 if lower == 0 else 2
    elif mnemonic == 'LA':
        return 2  # conservative: LUI + ADDI
    else:
        return 1  # all other pseudos expand to exactly 1 instruction


def assemble(input_file, output_file):
    with open(input_file, 'r') as f:
        lines = f.readlines()

    # ---- Pass 1: collect labels and compute PC for each line ----
    labels = {}
    raw_lines = []
    pc = 0

    for line in lines:
        line = line.split(';')[0].strip()
        if not line:
            continue
        # Handle labels (possibly multiple on one line)
        while ':' in line:
            label, rest = line.split(':', 1)
            labels[label.strip()] = pc
            line = rest.strip()
        if line:
            parts = re.split(r'\s+', line, 1)
            mnemonic = parts[0].upper()
            args_str = parts[1] if len(parts) > 1 else ""
            args = parse_args(args_str)

            if mnemonic in INSTRUCTIONS:
                info = INSTRUCTIONS[mnemonic]
                if info[0] == 'PSEUDO':
                    pc += 4 * count_pseudo_words(mnemonic, args, labels)
                else:
                    pc += 4
            else:
                raise ValueError(f"Unknown mnemonic: {mnemonic}")

            raw_lines.append(line)

    # ---- Pass 2: re-compute PC with final labels, then encode ----
    # Re-parse to get accurate PC (labels are now known for LI/LA sizing)
    labels2 = {}
    instruction_list = []  # (pc, mnemonic, args)
    pc = 0

    for line_orig in lines:
        line = line_orig.split(';')[0].strip()
        if not line:
            continue
        while ':' in line:
            label, rest = line.split(':', 1)
            labels2[label.strip()] = pc
            line = rest.strip()
        if line:
            parts = re.split(r'\s+', line, 1)
            mnemonic = parts[0].upper()
            args_str = parts[1] if len(parts) > 1 else ""
            args = parse_args(args_str)

            info = INSTRUCTIONS[mnemonic]
            if info[0] == 'PSEUDO':
                n = count_pseudo_words(mnemonic, args, labels2)
                instruction_list.append((pc, mnemonic, args))
                pc += 4 * n
            else:
                instruction_list.append((pc, mnemonic, args))
                pc += 4

    # Merge labels
    labels.update(labels2)

    # ---- Pass 3: encode ----
    binary_prog = []
    for current_pc, mnemonic, args in instruction_list:
        info = INSTRUCTIONS[mnemonic]
        try:
            if info[0] == 'PSEUDO':
                expanded = expand_pseudo(mnemonic, args, current_pc, labels)
                epc = current_pc
                for emnem, eargs in expanded:
                    word = encode_instruction(emnem, eargs, epc, labels)
                    binary_prog.append(word)
                    epc += 4
            else:
                word = encode_instruction(mnemonic, args, current_pc, labels)
                binary_prog.append(word)
        except Exception as e:
            print(f"Error at PC 0x{current_pc:04x}: {mnemonic} {' '.join(args)}")
            raise e

    # ---- Write output ----
    with open(output_file, 'w') as f:
        for instr in binary_prog:
            f.write(f"{instr:08x}\n")

    print(f"Successfully assembled {len(binary_prog)} instructions to {output_file}")


def parse_args(args_str):
    """Parse argument string, respecting parentheses in memory operands."""
    args = []
    if not args_str.strip():
        return args
    curr_arg = ""
    paren_count = 0
    for char in args_str:
        if char == '(':
            paren_count += 1
        elif char == ')':
            paren_count -= 1
        if char == ',' and paren_count == 0:
            args.append(curr_arg.strip())
            curr_arg = ""
        else:
            curr_arg += char
    args.append(curr_arg.strip())
    return args


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python assembler.py <input.asm> [output.mem]")
    else:
        infile = sys.argv[1]
        outfile = sys.argv[2] if len(sys.argv) > 2 else "rom_init.mem"
        assemble(infile, outfile)