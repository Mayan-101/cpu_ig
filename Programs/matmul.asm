; Float Matrix Multiplication (4x2 * 2x6 -> 4x6)
; C[i][j] = Sum_{k=0}^{1} (A[i][k] * B[k][j])

; Memory Map
; A: 0x10000000 (8 floats)
; B: 0x10000100 (12 floats)
; C: 0x10000200 (24 floats)

; --- Initialization ---
LUI x1, 0x10000
ADDI x2, x1, 100
ADDI x3, x1, 200

; Fill A and B with 1.0 (0x3F800000)
LUI x11, 0x3F800       ; x11 = 1.0

ADDI x12, x0, 8        ; Count A
InitA:
SW x11, 0(x1)
ADDI x1, x1, 4
ADDI x12, x12, -1
BNE x12, x0, InitA

ADDI x12, x0, 12       ; Count B
InitB:
SW x11, 0(x2)
ADDI x2, x2, 4
ADDI x12, x12, -1
BNE x12, x0, InitB

; --- Matrix Multiplications ---
LUI x1, 0x10000        ; Base A
ADDI x2, x1, 100       ; Base B
ADDI x3, x1, 200       ; Base C

ADDI x10, x0, 0        ; i = 0
LoopI:
    ADDI x11, x0, 0    ; j = 0
    LoopJ:
        ; sum = 0.0
        ADDI x13, x0, 0 ; 0x00000000 is 0.0 float
        
        ADDI x12, x0, 0 ; k = 0
        LoopK:
            ; Load A[i][k]
            ; index = i * 2 + k
            SLLI x14, x10, 1   ; x14 = i * 2
            ADD x14, x14, x12  ; x14 = i * 2 + k
            SLLI x14, x14, 2   ; x14 = (i * 2 + k) * 4 (offset)
            ADD x14, x14, x1   ; x14 = addr A[i][k]
            LW x15, 0(x14)     ; x15 = A[i][k]
            
            ; Load B[k][j]
            ; index = k * 6 + j
            SLLI x14, x12, 2   ; x14 = k * 4
            SLLI x17, x12, 1   ; x17 = k * 2
            ADD x14, x14, x17  ; x14 = k * 6
            ADD x14, x14, x11  ; x14 = k * 6 + j
            SLLI x14, x14, 2   ; x14 = offset
            ADD x14, x14, x2   ; x14 = addr B[k][j]
            LW x16, 0(x14)     ; x16 = B[k][j]
            
            ; mult = A[i][k] * B[k][j]
            FMUL x17, x15, x16
            ; sum += mult
            FADD x13, x13, x17
            
            ADDI x12, x12, 1   ; k++
            ADDI x14, x0, 2
            BNE x12, x14, LoopK
            
        ; Store C[i][j] = sum
        ; index = i * 6 + j
        SLLI x14, x10, 2
        SLLI x17, x10, 1
        ADD x14, x14, x17      ; x14 = i * 6
        ADD x14, x14, x11      ; x14 = i * 6 + j
        SLLI x14, x14, 2       ; x14 = offset
        ADD x14, x14, x3       ; x14 = addr C[i][j]
        SW x13, 0(x14)
        
        ADDI x11, x11, 1       ; j++
        ADDI x14, x0, 6
        BNE x11, x14, LoopJ
        
    ADDI x10, x10, 1           ; i++
    ADDI x14, x0, 4
    BNE x10, x14, LoopI

HLT
