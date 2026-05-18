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

## Performance Profiling & Cycle Tracing
You can run any `.asm` program through the cycle-accurate tracer to analyze pipeline performance, T-states, and stalls (e.g. load-use hazards, cache misses). 

1. Ensure Python and `matplotlib` are installed.
2. Run the trace batch script:
```powershell
.\Scripts\run_cycle_trace.bat <program_name>
```

This will automatically:
- Assemble your code using `assembler.py`
- Compile and run the `tb_cycle_tracer.v` simulation
- Export the text trace to `Traces/<program_name>_trace.txt`
- Run the python visualiser `Assembler/plot_cycles.py`
- Generate and save pipeline waterfall and summary charts in the `Traces/` directory (e.g., `Traces/<program_name>_waterfall.png`).
