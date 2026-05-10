# Getting Started

Follow these steps to get your simulation environment running.

## Prerequisites

- **Icarus Verilog**: Ensure `iverilog` and `vvp` are in your system PATH.
- **Python 3**: Required for the assembler.

## Fast Run

To verify your installation, run the `program` program:

1.  Open PowerShell in the project root.
2.  Run the command:
    ```powershell
    .\Scripts\test_program.bat program 0 10 0
    ```
3.  You should see:
    - `Successfully assembled...`
    - `[SUCCESS] HLT instruction reached...`

## Project Structure

- `ALU/`: Core arithmetic modules (Integer and Floating Point).
- `Assembler/`: Python assembler.
- `Memory/`: ITCM, DTCM, and Cache hierarchy modules.
- `Pipeline/`: Top-level CPU core and pipeline stage registers.
- `Programs/`: Assembly source files.
- `Scripts/`: Automation scripts.
- `SystemTests/`: Universal testbench and system integration.
