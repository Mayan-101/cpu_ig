; RV32I Memory Test Suite
; Stores results in memory at 0x10000 (first 10 elements)

; --- Result Array Initialization ---
LUI x1, 0x10000    ; Result base address

; --- Setup Data Space ---
ADDI x2, x1, 64    ; Use address + 64 as a scratch pad
LI x3, 0x12345678
SW x3, 0(x2)       ; Store test word

; --- Word Access ---
LW x4, 0(x2)       ; Load back
SW x4, 0(x1)       ; [0] = Loaded Word (0x12345678)

; --- Byte Access ---
LI x5, 0xAB
SB x5, 4(x2)
LB x6, 4(x2)       ; Signed load
SW x6, 4(x1)       ; [1] = Loaded Byte Signed (0xFFFFFFAB)

LBU x7, 4(x2)      ; Unsigned load
SW x7, 8(x1)       ; [2] = Loaded Byte Unsigned (0x000000AB)

; --- Half-word Access ---
LI x8, 0xCDEF
SH x8, 8(x2)
LH x9, 8(x2)       ; Signed load
SW x9, 12(x1)      ; [3] = Loaded Half Signed (0xFFFFCDEF)

LHU x10, 8(x2)     ; Unsigned load
SW x10, 16(x1)     ; [4] = Loaded Half Unsigned (0x0000CDEF)

; --- Final Marker ---
LI x11, 0xDEADBEEF
SW x11, 20(x1)     ; [5] = 0xDEADBEEF

HLT
