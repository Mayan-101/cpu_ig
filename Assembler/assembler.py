import sys
import re

# Define Instruction Formats and Opcodes
# Based on opcode_table.md

OPCODES = {
    # Group 1: R-type (0x00 - 0x0F)
    'NOP':  (0x00, 'R'),
    'ADD':  (0x01, 'R'),
    'SUB':  (0x02, 'R'),
    'AND':  (0x03, 'R'),
    'OR':   (0x04, 'R'),
    'XOR':  (0x05, 'R'),
    'NOT':  (0x06, 'R'),
    'SLL':  (0x07, 'R'),
    'SRL':  (0x08, 'R'),
    'SRA':  (0x09, 'R'),
    'ROR':  (0x0A, 'R'),
    'MUL':  (0x0B, 'R'),
    'MULH': (0x0C, 'R'),
    'DIV':  (0x0D, 'R'),
    'MOD':  (0x0E, 'R'),
    'CMP':  (0x0F, 'R'),

    # Group 2: I-type ALU (0x10 - 0x1B)
    'ADDI': (0x10, 'I'),
    'SUBI': (0x11, 'I'),
    'ANDI': (0x12, 'I'),
    'ORI':  (0x13, 'I'),
    'XORI': (0x14, 'I'),
    'SLLI': (0x15, 'I'),
    'SRLI': (0x16, 'I'),
    'SRAI': (0x17, 'I'),
    'CMPI': (0x18, 'I'),
    'MOVI': (0x19, 'I'),
    'LUI':  (0x1A, 'L'), # L-type
    'ADDC': (0x1B, 'I'),

    # Group 3: Load/Store (I-type)
    'LW':   (0x20, 'M'), # M-type (Memory: rd, imm(rs1))
    'SW':   (0x21, 'M'),
    'LB':   (0x22, 'M'),
    'SB':   (0x23, 'M'),
    'LH':   (0x24, 'M'),
    'SH':   (0x25, 'M'),
    'LBU':  (0x26, 'M'),
    'LHU':  (0x27, 'M'),

    # Group 4: Float (R-type)
    'FADD': (0x28, 'R'),
    'FSUB': (0x29, 'R'),
    'FMUL': (0x2A, 'R'),
    'FCMP': (0x2B, 'R'),
    'ITOF': (0x2C, 'R'),
    'FTOI': (0x2D, 'R'),
    'FMOV': (0x2E, 'R'),

    # Group 5: Branch (I-type)
    'BEQ':  (0x30, 'B'), # B-type (Branch: rs1, rs2, offset)
    'BNE':  (0x31, 'B'),
    'BLT':  (0x32, 'B'),
    'BGT':  (0x33, 'B'),
    'BLE':  (0x34, 'B'),
    'BGE':  (0x35, 'B'),
    'BLTU': (0x36, 'B'),
    'BGEU': (0x37, 'B'),

    # Group 6: Jump/Call
    'JAL':  (0x38, 'J'), # J-type
    'JALR': (0x39, 'I'),
    'CALL': (0x3A, 'J'),
    'RET':  (0x3B, 'R'),
    'RETI': (0x3C, 'R'),

    # Group 8: MISC (Opcode 0x3F)
    'HLT':   (0x3F, 'MISC', 0x00),
    'PUSH':  (0x3F, 'MISC', 0x01),
    'POP':   (0x3F, 'MISC', 0x02),
    'MOVSP': (0x3F, 'MISC', 0x03),
    'GETSP': (0x3F, 'MISC', 0x04),
    'SETB':  (0x3F, 'MISC', 0x05),
    'CLRB':  (0x3F, 'MISC', 0x06),
    'TESTB': (0x3F, 'MISC', 0x07),
    'SEI':   (0x3F, 'MISC', 0x08),
    'CLI':   (0x3F, 'MISC', 0x09),
    'ADDC_R':(0x3F, 'MISC', 0x0A), # R-type ADDC
    'SUBC':  (0x3F, 'MISC', 0x0B),
    'SWAP':  (0x3F, 'MISC', 0x0C),
    'MOV':   (0x3F, 'MISC', 0x0D),
}

REGS = {f'x{i}': i for i in range(32)}
REGS.update({
    'acc': 32,
    'b': 33,
    'zero': 0,
    'ra': 32, # acc used as return address in JAL
})

def parse_reg(reg_str):
    reg_str = reg_str.lower().strip(',')
    if reg_str in REGS:
        return REGS[reg_str]
    # Remove 'x' if it exists and try to parse as number
    if reg_str.startswith('x'):
        try:
            return int(reg_str[1:])
        except:
            pass
    raise ValueError(f"Invalid register: {reg_str}")

def parse_imm(imm_str):
    imm_str = imm_str.strip('#').strip(',')
    if imm_str.startswith('0x'):
        return int(imm_str, 16)
    return int(imm_str)

def encode_instr(opcode, format_info, args, current_pc, labels):
    op = opcode[0]
    fmt = format_info

    if fmt == 'R':
        # MNEM rd, rs1, rs2
        rd = parse_reg(args[0])
        rs1 = parse_reg(args[1]) if len(args) > 1 else 0
        rs2 = parse_reg(args[2]) if len(args) > 2 else 0
        return (op << 26) | (rd << 20) | (rs1 << 14) | (rs2 << 8)
    
    elif fmt == 'I':
        # MNEM rd, rs1, #imm
        rd = parse_reg(args[0])
        rs1 = parse_reg(args[1])
        imm = parse_imm(args[2])
        return (op << 26) | (rd << 20) | (rs1 << 14) | (imm & 0x3FFF)
    
    elif fmt == 'L':
        # MNEM rd, #imm20
        rd = parse_reg(args[0])
        imm = parse_imm(args[1])
        return (op << 26) | (rd << 20) | (imm & 0xFFFFF)
    
    elif fmt == 'M':
        # MNEM rd, #imm(rs1)
        rd = parse_reg(args[0])
        # Match format like 8(x5) or #8(x5)
        match = re.search(r'#?(-?\d+|0x[0-9a-fA-F]+)\s*\(\s*(\w+)\s*\)', args[1])
        if not match:
            raise ValueError(f"Invalid memory operand: {args[1]}")
        imm = parse_imm(match.group(1))
        rs1 = parse_reg(match.group(2))
        return (op << 26) | (rd << 20) | (rs1 << 14) | (imm & 0x3FFF)
    
    elif fmt == 'B':
        # MNEM rs1, rs2, offset/label
        rs1 = parse_reg(args[0])
        rs2 = parse_reg(args[1])
        target = args[2]
        if target in labels:
            # Branch target is PC + 4 + offset * 4
            offset = (labels[target] - (current_pc + 4)) // 4
        else:
            offset = parse_imm(target)
        return (op << 26) | (rs2 << 20) | (rs1 << 14) | (offset & 0x3FFF)
    
    elif fmt == 'J':
        # MNEM target
        target = args[0]
        if target in labels:
            # JAL target is absolute? No, based on ACC = PC+4; PC = {PC[31:28], target26, 2'b00}
            # So it's a 26-bit word address.
            target_addr = labels[target] >> 2
        else:
            target_addr = parse_imm(target)
        return (op << 26) | (target_addr & 0x3FFFFFF)
    
    elif fmt == 'MISC':
        # MNEM rd, rs1, rs2
        funct = opcode[2]
        rd = parse_reg(args[0]) if len(args) > 0 else 0
        rs1 = parse_reg(args[1]) if len(args) > 1 else 0
        rs2 = parse_reg(args[2]) if len(args) > 2 else 0
        return (op << 26) | (rd << 20) | (rs1 << 14) | (rs2 << 8) | funct

    return 0

def assemble(input_file, output_file):
    with open(input_file, 'r') as f:
        lines = f.readlines()

    labels = {}
    instructions = []
    pc = 0

    # Pass 1: Labels
    for line in lines:
        line = line.split(';')[0].strip() # Remove comments
        if not line:
            continue
        
        # Handle labels on separate lines or same line
        while ':' in line:
            label, rest = line.split(':', 1)
            labels[label.strip()] = pc
            line = rest.strip()
        
        if line:
            instructions.append((pc, line))
            pc += 4

    # Pass 2: Encoding
    binary_prog = []
    for current_pc, line in instructions:
        # Split by first whitespace to get mnemonic
        parts = re.split(r'\s+', line, 1)
        mnemonic = parts[0].upper()
        args_str = parts[1] if len(parts) > 1 else ""
        
        # Split args by comma, but be careful of commas inside parenthesis
        # We'll use a simpler approach for now
        args = []
        if args_str:
            # Split by comma but ignore commas inside parentheses
            curr_arg = ""
            paren_count = 0
            for char in args_str:
                if char == '(': paren_count += 1
                elif char == ')': paren_count -= 1
                
                if char == ',' and paren_count == 0:
                    args.append(curr_arg.strip())
                    curr_arg = ""
                else:
                    curr_arg += char
            args.append(curr_arg.strip())

        if mnemonic not in OPCODES:
            raise ValueError(f"Unknown mnemonic: {mnemonic} at PC {current_pc}")
        
        opcode_info = OPCODES[mnemonic]
        fmt = opcode_info[1]
        
        try:
            instr_bin = encode_instr(opcode_info, fmt, args, current_pc, labels)
            binary_prog.append(instr_bin)
        except Exception as e:
            print(f"Error assembling line: {line}")
            raise e

    # Output as hex (for Verilog $readmemh)
    with open(output_file, 'w') as f:
        for instr in binary_prog:
            f.write(f"{instr:08x}\n")
    
    print(f"Successfully assembled {len(binary_prog)} instructions to {output_file}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python assembler.py <input.asm> [output.mem]")
    else:
        infile = sys.argv[1]
        outfile = sys.argv[2] if len(sys.argv) > 2 else "rom_init.mem"
        assemble(infile, outfile)
