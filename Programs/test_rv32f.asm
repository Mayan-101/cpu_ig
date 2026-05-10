; RV32F Floating-Point Test Suite
; Stores bit patterns in memory at 0x10000

; --- Result Array Initialization ---
LUI x1, 0x10000    ; Result base address

; --- Operands ---
LI x2, 0x3f800000  ; 1.0
LI x3, 0x40000000  ; 2.0

; --- Basic Ops ---
FADD x4, x2, x3    ; x4 = 3.0 (0x40400000)
SW x4, 0(x1)       ; [0] = 0x40400000

FSUB x5, x3, x2    ; x5 = 1.0 (0x3f800000)
SW x5, 4(x1)       ; [1] = 0x3f800000

FMUL x6, x3, x3    ; x6 = 4.0 (0x40800000)
SW x6, 8(x1)       ; [2] = 0x40800000

; --- Conversion ---
LI x7, 10
ITOF x8, x7        ; x8 = 10.0 (0x41200000)
SW x8, 12(x1)      ; [3] = 0x41200000

FTOI x9, x8        ; x9 = 10
SW x9, 16(x1)      ; [4] = 10

; --- Final Marker ---
LI x10, 0xDEADBEEF
SW x10, 20(x1)     ; [5] = 0xDEADBEEF

HLT
