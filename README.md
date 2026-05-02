# RISC CPU Documentation

Welcome to the documentation for the 5-stage pipelined RISC CPU.

## Contents

- [**Getting Started**](GettingStarted.md): Environment setup and first run.
- [**ISA Reference**](ISA.md): Full instruction set and register documentation.
- [**Memory Map**](MemoryMap.md): System address layout.
- [**Usage & Testing**](Usage.md): How to write and run programs.

## Key Features

- **5-Stage Pipeline**: IF, ID, EX, MEM, WB.
- **Hazard Unit**: Full data forwarding and load-use stall detection.
- **FPU Integrated**: Support for floating-point arithmetic and conversions.
- **Automated Toolchain**: Integrated Python assembler and Icarus Verilog testbench.
