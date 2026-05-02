; Float Array Subtraction (Size 6)
; C[i] = A[i] - B[i]

; Memory Setup
LUI x1, 0x20000        ; x1 = RAM Start (Base for A)
ADDI x2, x1, 100       ; x2 = Base for B
ADDI x3, x1, 200       ; x3 = Base for C

; Initialization
; A[i] = 10.0 (0x41200000), B[i] = 4.0 (0x40800000)
LUI x11, 0x41200       ; x11 = 10.0
LUI x12, 0x40800       ; x12 = 4.0

ADDI x5, x0, 6         ; Init counter
InitLoop:
SW x11, 0(x1)          ; A[i] = 10.0
SW x12, 0(x2)          ; B[i] = 4.0
ADDI x1, x1, 4
ADDI x2, x2, 4
ADDI x5, x5, -1
BNE x5, x0, InitLoop

; Reset Pointers
LUI x1, 0x20000
ADDI x2, x1, 100
ADDI x3, x1, 200
ADDI x4, x0, 6

SubLoop:
LW x5, 0(x1)           ; Load A[i]
LW x6, 0(x2)           ; Load B[i]
FSUB x7, x5, x6        ; x7 = A[i] - B[i]
SW x7, 0(x3)           ; Store C[i]
ADDI x1, x1, 4
ADDI x2, x2, 4
ADDI x3, x3, 4
ADDI x4, x4, -1
BNE x4, x0, SubLoop

HLT
