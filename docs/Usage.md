# Running and Testing

The CPU environment includes an automated script to assemble, compile, and simulate programs.

## Using the Universal Testbench

Run the `test_universal.bat` script located in the `Scripts/` folder.

```powershell
.\Scripts\test_universal.bat <program> [start] [end] [hex]
```

### Parameters

1.  **`<program>`**: The filename of your `.asm` file in the `Programs/` directory (exclude the extension).
2.  **`[start]`**: (Optional) The starting decimal index in RAM to dump.
3.  **`[end]`**: (Optional) The ending decimal index in RAM to dump.
4.  **`[hex]`**: (Optional) Set to `1` for hex output, `0` for decimal.

## Example

To run the `matmul` program and view the first 20 results in hex:
```powershell
.\Scripts\test_universal.bat matmul 0 20 1
```

## Adding New Programs

1.  Create a new `.asm` file in `Programs/`.
2.  Use the assembly syntax defined in `ISA.md`.
3.  End your program with `HLT` to stop the simulation.
4.  Run the test script with your program name.
