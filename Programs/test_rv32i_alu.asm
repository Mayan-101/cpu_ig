; RV32I ALU Test Suite
; Stores results in memory at 0x10000 (first 10 elements)

; --- Result Array Initialization ---
LUI x1, 0x10000    ; Result base address

; --- Setup Operands ---
LI x2, 10
LI x3, 20
LI x4, -5

; --- Arithmetic ---
ADD x5, x2, x3     ; x5 = 30
SW  x5, 0(x1)      ; [0] = 30

SUB x6, x3, x2     ; x6 = 10
SW  x6, 4(x1)      ; [1] = 10

; --- Logical ---
AND x7, x2, x3     ; x7 = 10 & 20 = 0
SW  x7, 8(x1)      ; [2] = 0

OR  x8, x2, x3     ; x8 = 10 | 20 = 30
SW  x8, 12(x1)     ; [3] = 30

XOR x9, x2, x3     ; x9 = 10 ^ 20 = 30
SW  x9, 16(x1)     ; [4] = 30

; --- Shifts ---
LI  x10, 1
SLLI x11, x10, 4   ; x11 = 16
SW  x11, 20(x1)    ; [5] = 16

LI  x12, -1        ; 0xFFFFFFFF
SRAI x13, x12, 1   ; x13 = 0xFFFFFFFF
SW  x13, 24(x1)    ; [6] = 0xFFFFFFFF

; --- Comparison ---
SLT x14, x4, x2    ; x14 = (-5 < 10) = 1
SW  x14, 28(x1)    ; [7] = 1

SLTU x15, x4, x2   ; x15 = (LargeU < 10) = 0
SW  x15, 32(x1)    ; [8] = 0

; --- Final Marker ---
LI  x16, 0xDEADBEEF
SW  x16, 36(x1)    ; [9] = 0xDEADBEEF

HLT
