## Quick Start

1.  **Modify Code**: Edit the `.asm` file in `Programs/`.
2.  **Modify Data**: Edit `Programs/ram_init.mem` to initialize RAM at `0x20000000`.
3.  **Run**: Use the automated script:
    ```powershell
    .\Scripts\test_universal.bat <program_name>
    ```

### Example
To test bubble sort with your own data:
1.  Put your hex values in `Programs/ram_init.mem`.
2.  Run: `.\Scripts\test_universal.bat bubble_sort`

### Script Parameters
`.\Scripts\test_universal.bat <name> [dump_start] [dump_end] [hex_mode]`

- **`<name>`**: The `.asm` filename (without extension).
- **`[dump_start/end]`**: The decimal range of RAM to display at the end.
- **`[hex_mode]`**: Set to `1` for Hex output, `0` for Decimal.

### Example Commands
- **Basic Run**: `.\Scripts\test_universal.bat bubble_sort 0 10 0`
- **Matrix Multiplication (Hex Mode)**: `.\Scripts\test_universal.bat matmul 0 32 1`

> **Note**: The script automatically re-assembles your `.asm` into a `.mem` file before each run. Only edit `.asm` (for code) and `ram_init.mem` (for data).
