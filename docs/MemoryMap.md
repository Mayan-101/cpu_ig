# Memory Map 


## Overview

- **Address Space**: 32-bit (4 GB theoretical)
- **Maximum External RAM**: 16 MB
- **Key Features**: Tightly Coupled Memory (TCM) for deterministic execution, Memory-Mapped I/O, and cacheable region separation.

## Memory Map

| Start Address       | End Address         | Size          | Region                        | Cacheable | Attributes                          | Purpose |
|---------------------|---------------------|---------------|-------------------------------|-----------|-------------------------------------|---------|
| `0x0000_0000`       | `0x0000_FFFF`       | **64 KB**     | **ITCM** (Instruction TCM)    | No        | Executable, Low Latency             | Boot code, Interrupt handlers, Critical code |
| `0x0001_0000`       | `0x0001_FFFF`       | **64 KB**     | **DTCM** (Data TCM)           | No        | Low Latency, Deterministic          | Stack, Critical data, Real-time variables |
| `0x0002_0000`       | `0x0002_FFFF`       | **64 KB**     | **Shared Scratchpad (LIM)**   | No        | Shared across cores                 | Inter-core communication, Shared buffers |
| `0x0003_0000`       | `0x0FFF_FFFF`       | ~255 MB       | Reserved                      | -         | -                                   | Future use |
| `0x1000_0000`       | `0x10FF_FFFF`       | **16 MB**     | **External DDR / Main RAM**   | **Yes**   | Cached (L1 + L2)                    | General purpose memory, Heap, Large data |
| `0x1100_0000`       | `0x3FFF_FFFF`       | ~768 MB       | Reserved                      | -         | -                                   | Future expansion |
| `0x4000_0000`       | `0x4FFF_FFFF`       | 256 MB        | **Peripherals (MMIO)**        | No        | Device Registers                    | UART, GPIO, Timers, SPI, etc. |
| `0x5000_0000`       | `0x7FFF_FFFF`       | ~768 MB       | Reserved                      | -         | -                                   | Future peripherals |
| `0x8000_0000`       | `0x8000_0FFF`       | **4 KB**      | **Core CSRs**                 | No        | CPU Control & Status Registers      | Configuration, Status, Cache control |
| `0x8000_1000`       | `0x8FFF_FFFF`       | ~256 MB       | Reserved                      | -         | -                                   | Future system registers |
| `0xF000_0000`       | `0xFFFF_FFFF`       | 256 MB        | Debug / Trace                 | No        | -                                   | Debug module, Trace buffer (future) |

### Detailed Peripheral Map (`0x4000_0000` base)

| Base Address        | Size     | Peripheral              | Notes |
|---------------------|----------|-------------------------|-------|
| `0x4000_0000`       | 64 KB    | UART0                   | Primary UART |
| `0x4001_0000`       | 64 KB    | UART1                   | Secondary UART |
| `0x4002_0000`       | 64 KB    | GPIO                    | General Purpose I/O |
| `0x4003_0000`       | 64 KB    | Timer / CLINT           | Machine timer, Software interrupts |
| `0x4004_0000`       | 256 KB   | PLIC                    | Platform-Level Interrupt Controller (optional) |
| `0x4008_0000`       | 128 KB   | Custom Accelerators     | Future use |
| `0x4010_0000`       | -        | Reserved                | - |

---

## Region Attributes Summary

- **Cacheable**: Only `0x1000_0000` – `0x10FF_FFFF` (Main RAM)
- **Non-cacheable**: TCM, Scratchpad, Peripherals, CSRs
- **Executable**: ITCM + Main RAM (after enabling MMU/PMP if implemented)
- **Deterministic**: TCM regions (fixed latency, no cache misses)

## Recommendations

- Bootloader should start from **ITCM** (`0x0000_0000`).
- Critical real-time code and ISRs should run from **ITCM**.
- Stack pointer should initially point inside **DTCM**.
- Use CSRs to control cache (enable/disable, flush, etc.).

## Future Expansion

- Multi-core support: Private ITCM/DTCM per core + shared L2 + shared scratchpad.
- External memory can be extended beyond 16 MB by adjusting address decoding.

