; Bubble Sort of an array (Size 10)
; Goal: Sort array in ascending order

; --- Initialization ---
LUI x1, 0x20000        ; x1 = RAM Start
ADDI x2, x0, 10        ; size = 10

; Fill with some values: 10, 9, 8, 7, 6, 5, 4, 3, 2, 1
ADDI x3, x0, 10        ; val
ADDI x4, x0, 10        ; counter
InitLoop:
SW x3, 0(x1)
ADDI x3, x3, -1
ADDI x1, x1, 4
ADDI x4, x4, -1
BNE x4, x0, InitLoop

; --- Bubble Sort ---
LUI x1, 0x20000        ; Base address
ADDI x2, x0, 0         ; i = 0
ADDI x4, x0, 10        ; n = 10
ADDI x9, x0, 9         ; n - 1 = 9

OuterLoop:
    ADDI x3, x0, 0     ; j = 0
    InnerLoop:
        ; Calculate addresses for arr[j] and arr[j+1]
        SLLI x7, x3, 2 ; x7 = j * 4 (offset)
        ADD x7, x7, x1 ; x7 = addr of arr[j]
        ADDI x8, x7, 4 ; x8 = addr of arr[j+1]
        
        LW x5, 0(x7)   ; x5 = arr[j]
        LW x6, 0(x8)   ; x6 = arr[j+1]
        
        ; if arr[j] > arr[j+1] then swap
        CMP x10, x5, x6 ; x10 = arr[j] - arr[j+1]
        ; CMP usually sets flags or returns diff. 
        ; Based on assembler, CMP is R-type (0x0F).
        ; If x10 > 0, then x5 > x6.
        ; But wait, how do I branch on CMP? 
        ; BGT rs1, rs2, offset
        ; I can just use BGT x5, x6, SwapLabel
        
        BGT x5, x6, DoSwap
        JAL SkipSwap   ; Go to next iteration
        
        DoSwap:
        SW x6, 0(x7)
        SW x5, 0(x8)
        
        SkipSwap:
        ADDI x3, x3, 1 ; j++
        BNE x3, x9, InnerLoop
        
    ADDI x2, x2, 1     ; i++
    BNE x2, x9, OuterLoop

HLT
