; Sample Array Addition Program
; Goal: Initialize two arrays and add them

; Initialization
LUI x1, 0x10000        ; x1 = RAM Start (0x20000000)
ADDI x2, x1, 20        ; x2 = Array B Start (0x20000014)
ADDI x3, x1, 40        ; x3 = Array C Start (0x20000028)
ADDI x4, x0, 5         ; x4 = Count (5)

ADDI x10, x0, 1        ; Constant 1
ADDI x11, x0, 10       ; Constant 10
ADDI x12, x0, 0        ; Val A acc
ADDI x13, x0, 0        ; Val B acc

InitLoop:
ADD x12, x12, x10      ; valA += 1
SW x12, 0(x1)          ; MEM[x1] = valA
ADD x13, x13, x11      ; valB += 10
SW x13, 0(x2)          ; MEM[x2] = valB
ADDI x1, x1, 4         ; next x1
ADDI x2, x2, 4         ; next x2
ADDI x4, x4, -1        ; count--
BNE x4, x0, InitLoop

; Reset Pointers
LUI x1, 0x10000
ADDI x2, x1, 20
ADDI x3, x1, 40
ADDI x4, x0, 5

AddLoop:
LW x5, 0(x1)           ; valA = MEM[x1]
LW x6, 0(x2)           ; valB = MEM[x2]
ADD x7, x5, x6         ; sum = valA + valB
SW x7, 0(x3)           ; MEM[x3] = sum
ADDI x1, x1, 4
ADDI x2, x2, 4
ADDI x3, x3, 4
ADDI x4, x4, -1
BNE x4, x0, AddLoop

HLT                    ; Done
