; Custom Extensions and System Test Suite
; Stores status in memory at 0x10000

; --- Result Array Initialization ---
LUI x1, 0x10000    ; Result base address

; --- IO Test ---
LI x2, 0xAA
OUT x2, 0x10       ; Output 0xAA
IN x3, 0x10        ; Input 0xAA (assuming loopback or sim behavior)
SW x3, 0(x1)       ; [0] = Input Value

; --- Interrupt Control Flags ---
LI x4, 0x1
SEI
SW x4, 4(x1)       ; [1] = 1 (SEI Reached)

LI x5, 0x2
CLI
SW x5, 8(x1)       ; [2] = 2 (CLI Reached)

; --- Final Marker ---
LI x6, 0xDEADBEEF
SW x6, 12(x1)      ; [3] = 0xDEADBEEF

HLT
