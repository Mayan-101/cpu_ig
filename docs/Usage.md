## Quick Start

1.  **Modify Code**: Edit the `.asm` file in `Programs/`.
2.  **Modify Data**: Edit `Programs/ram_init.mem` to initialize RAM at `0x1000_0000`.
3.  **Run**: Use the automated script:
    ```powershell
    .\Scripts\test_program.bat <program_name>
    ```

### Memory Map for Development
- **Code (ITCM)**: `0x0000_0000` (Fastest for instructions)
- **Stack/Data (DTCM)**: `0x0001_0000` (Fastest for stack and local data)
- **Main Data (RAM)**: `0x1000_0000` (Cached)

### Example
To test bubble sort with your own data:
1.  Put your hex values in `Programs/ram_init.mem` (Loaded at `0x1000_0000`).
2.  Run: `.\Scripts\test_program.bat bubble_sort`

### Script Parameters
`.\Scripts\test_program.bat <name> [dump_start] [dump_end] [hex_mode]`

- **`<name>`**: The `.asm` filename (without extension).
- **`[dump_start/end]`**: The decimal range of RAM to display at the end.
- **`[hex_mode]`**: Set to `1` for Hex output, `0` for Decimal.

### Example Commands
- **Basic Run**: `.\Scripts\test_program.bat bubble_sort 0 10 0`
- **Floating Point Test**: `.\Scripts\test_program.bat float_add 0 10 1`

> **Note**: The script automatically re-assembles your `.asm` into a `.mem` file before each run. Only edit `.asm` (for code) and `ram_init.mem` (for data).

