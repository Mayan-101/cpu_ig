; RV32I Control Flow Test Suite
; Stores checkpoints in memory at 0x10000

; --- Result Array Initialization ---
LUI x1, 0x10000    ; Result base address

; --- JAL Test ---
JAL x3, JAL_Target
LI x4, 0xBAD
SW x4, 0(x1)       ; Should be skipped
JAL_Target:
LI x5, 0x1
SW x5, 0(x1)       ; [0] = 1 (JAL Success)

; --- JALR Test ---
LA x6, JALR_Target
JALR x7, x6, 0
LI x8, 0xBAD
SW x8, 4(x1)       ; Should be skipped
JALR_Target:
LI x9, 0x1
SW x9, 4(x1)       ; [1] = 1 (JALR Success)

; --- BEQ Test (Taken) ---
LI x10, 10
LI x11, 10
BEQ x10, x11, BEQ_Taken
LI x12, 0xBAD
SW x12, 8(x1)      ; Should be skipped
BEQ_Taken:
LI x13, 0x1
SW x13, 8(x1)      ; [2] = 1 (BEQ Success)

; --- BNE Test (Not Taken) ---
LI x14, 10
LI x15, 10
BNE x14, x15, BNE_Fail
LI x16, 0x1
SW x16, 12(x1)     ; [3] = 1 (BNE Success)
JAL x0, Skip_BNE_Fail
BNE_Fail:
LI x17, 0xBAD
SW x17, 12(x1)
Skip_BNE_Fail:

; --- Final Marker ---
LI x18, 0xDEADBEEF
SW x18, 16(x1)     ; [4] = 0xDEADBEEF

HLT
