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
- **Cache Integrated**: 4-way Set Associative, Write-Back, LRU replacement policy, Write-Allocate Cache.
- **Automated Toolchain**: Integrated Python assembler and Icarus Verilog testbench.

## ToDo List
- [ ] Add support for Interrupts (Intregation with SoC).
- [ ] Add support for virtual memory.
- [ ] Add support for Paged Virtual Memory.
- [ ] Add support for MMU.
- [ ] Add support for out-of-order execution.
- [ ] Add support for branch prediction.
- [ ] Add support for multiple cores.



