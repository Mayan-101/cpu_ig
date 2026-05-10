; RV32M Multiply/Divide Test Suite
; Stores results in memory at 0x10000

; --- Result Array Initialization ---
LUI x1, 0x10000    ; Result base address

; --- Setup Operands ---
LI x2, 10
LI x3, 20

; --- Multiplication ---
MUL x4, x2, x3     ; x4 = 200
SW x4, 0(x1)       ; [0] = 200

LI x5, -1
LI x6, 2
MUL x7, x5, x6     ; x7 = -2
SW x7, 4(x1)       ; [1] = -2

MULH x8, x5, x6    ; x8 = -1 (Upper bits of -2)
SW x8, 8(x1)       ; [2] = -1

; --- Division ---
LI x9, 100
LI x10, 7
DIV x11, x9, x10   ; x11 = 14
SW x11, 12(x1)     ; [3] = 14

REM x12, x9, x10   ; x12 = 2
SW x12, 16(x1)     ; [4] = 2

; --- Special Cases ---
LI x13, 1
DIV x14, x13, x0   ; Divide by zero
SW x14, 20(x1)     ; [5] = -1 (Standard RV32M behavior)

; --- Final Marker ---
LI x15, 0xDEADBEEF
SW x15, 24(x1)     ; [6] = 0xDEADBEEF

HLT
