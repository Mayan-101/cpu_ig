# Memory Map

The system uses a 32-bit unified memory address space.

| Base Address | Size | Device | Description |
| :--- | :--- | :--- | :--- |
| `0x0000_0000` | 256 KB | **ROM** | Program memory (Read-only) |
| `0x2000_0000` | 64 KB | **RAM** | Main data memory (Read/Write) |
| `0x4000_0000` | 4 KB | **I/O** | Peripheral Control Registers |
| `0x8000_0000` | 4 KB | **SYS** | CSR and CPU Status Registers |

## System Registers (CSR)

The CPU status and control registers are mapped to the `0x8000_0000` range.

- `0x8000_0000`: `MTVEC` (Trap Vector Base Address)
- `0x8000_0004`: `MEPC` (Machine Exception Program Counter)
- `0x8000_0008`: `MSTATUS` (Machine Status Register)
