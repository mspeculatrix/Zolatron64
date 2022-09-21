; ZERO PAGE CONFIG -- cfg_page_0.asm -------------------------------------------

MSG_VEC       = $50    	 		        ; $50 Message to print
FUNC_RES_L    = MSG_VEC + 2         ; $52 For 16-bit subroutine results. Must be
FUNC_RES_H    = FUNC_RES_L + 1      ; $53 in zero page.
FUNC_RESULT   = FUNC_RES_H + 1      ; $54 To hold the 8-bit result of a subroutine
FUNC_ERR      = FUNC_RESULT + 1	    ; $55 Store an error code for functions

TBL_VEC_L     = FUNC_ERR + 1        ; $56 Table vector - for searching tables
TBL_VEC_H     = TBL_VEC_L + 1       ; $57
TMP_ADDR_A    = TBL_VEC_H + 1       ; $58 Temp 2-byte vector/store for address
TMP_ADDR_A_L  = TMP_ADDR_A	        ; $58 - Alias -
TMP_ADDR_A_H  = TMP_ADDR_A + 1      ; $59
TMP_ADDR_B    = TMP_ADDR_A_H + 1    ; $5A Temp 2-byte vector/store for address
TMP_ADDR_B_L  = TMP_ADDR_B	        ; $5A - Alias -
TMP_ADDR_B_H  = TMP_ADDR_B + 1      ; $5B
TMP_ADDR_C    = TMP_ADDR_B_H + 1    ; $5C
TMP_ADDR_C_L  = TMP_ADDR_C	        ; $5C - Alias -
TMP_ADDR_C_H  = TMP_ADDR_C_L + 1	  ; $5D

FILE_ADDR     = TMP_ADDR_C_H + 1    ; $5E
LOMEM         = FILE_ADDR + 2       ; $60 First available byte after user prog

STDIN_STATUS_REG = LOMEM + 2	      ; $62 Used to store various flags
SYS_REG = STDIN_STATUS_REG + 1      ; $63 System Register
; SYSTEM REGISTER
; Bit     Flag name          Function
;  0
;  1      SYS_EXMEM_YES/NO     Extended memory fitted - 1=yes, 0=no
;  2      SYS_PARALLEL_YES/NO  Parallel board fitted  - 1=yes, 0=no
;  3
;  4
;  5      LCD_SIZE             0 = 2x16, 1 = 4x20
;  6
;  7
SYS_EXMEM_YES = %00000010 ; ORA with reg to set or test flag
SYS_EXMEM_NO = %11111101  ; AND with reg to unset flag
SYS_PARALLEL_YES = %00000100 ; ORA with reg to set or test flag
SYS_PARALLEL_NO  = %11111011  ; AND with reg to unset flag
