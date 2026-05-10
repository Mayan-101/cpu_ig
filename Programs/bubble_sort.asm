; Bubble Sort of an array (Size 10)
; Goal: Sort array in ascending order

; --- Initialization ---
LUI x1, 0x10000        ; x1 = RAM Start
ADDI x2, x0, 10        ; size = 10

; --- Bubble Sort ---
LUI x1, 0x10000        ; Base address
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
        
        ; If arr[j] <= arr[j+1], branch past the swap entirely
        BGE x6, x5, SkipSwap   
        
        ; If we didn't branch, it means arr[j] > arr[j+1] (Swap them)
        DoSwap:
        SW x6, 0(x7)
        SW x5, 0(x8)

        SkipSwap:
        ADDI x3, x3, 1 ; j++
        BNE x3, x9, InnerLoop
        
    ADDI x2, x2, 1     ; i++
    BNE x2, x9, OuterLoop

HLT