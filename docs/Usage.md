# Usage Guide

## Quick Start

1.  **Modify Code**: Edit the `.asm` file in `Programs/`.
2.  **Modify Data**: Edit `Programs/ram_init.mem` to initialize RAM at `0x1000_0000`.
3.  **Run**: Use the automated script:
    ```powershell
    .\Scripts\test_program.bat <program_name>
    ```

## Toolchain Compatibility

The architecture is now compatible with standard RISC-V toolchains. You can use `riscv32-unknown-elf-gcc` to compile C code for this processor.

### Compiling C for the CPU
Example command for GCC:
```bash
riscv32-unknown-elf-gcc -march=rv32imf -mabi=ilp32f -o program.elf main.c
```

### Assembler
While standard `as` can be used, we provide a custom `assembler.py` that supports our custom extensions (`HLT`, `IN`, `OUT`, etc.) while maintaining standard RISC-V RV32I/M/F syntax.

```bash
python Assembler/assembler.py <input.asm> <output.mem>
```

## Memory Map for Development
- **Code (ITCM)**: `0x0000_0000` (Map to `.text`)
- **Stack/Data (DTCM)**: `0x0001_0000` (Fast stack access)
- **Main Data (RAM)**: `0x1000_0000` (Cached main memory)

## Examples
To test bubble sort:
1.  Initialize data in `Programs/ram_init.mem`.
2.  Run: `.\Scripts\test_program.bat bubble_sort`

### Script Parameters
`.\Scripts\test_program.bat <name> [dump_start] [dump_end] [hex_mode]`

- **`<name>`**: The `.asm` filename (without extension).
- **`[dump_start/end]`**: RAM range to display at completion.
- **`[hex_mode]`**: `1` for Hex, `0` for Decimal.
