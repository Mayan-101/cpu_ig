# It's a CPU, i guess... Bit RISCy 😭 

I hope you will read stuff below

## Contents

- [**Getting Started**](GettingStarted.md): Environment setup and first run.
- [**ISA Reference**](docs/ISA.md): Full instruction set and register documentation.
- [**Memory Map**](docs/MemoryMap.md): System address layout.
- [**Usage & Testing**](docs/Usage.md): How to write and run programs.

## Key Features

- **5-Stage Pipeline**: IF, ID, EX, MEM, WB.
- **Hazard Unit**: Full data forwarding and load-use stall detection.
- **FPU Integrated**: Support for floating-point arithmetic and conversions.
- **Tightly Coupled Memory**: Dedicated ITCM (16 KB) and DTCM (8 KB) for deterministic performance.
- **Hierarchical Cache**: Multi-level 4-way (L1) and 8-way (L2) cache subsystem.
- **Automated Toolchain**: Integrated Python assembler and Icarus Verilog regression suite.

## ToDo List
- [ ] Add support for Interrupts (Intregation with SoC).
- [ ] Add support for virtual memory.
- [ ] Add support for Paged Virtual Memory.
- [ ] Add support for MMU.
- [ ] Add support for out-of-order execution.
- [ ] Add support for branch prediction.
- [ ] Add support for multiple cores.



