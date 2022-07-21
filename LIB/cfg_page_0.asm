; ZERO PAGE CONFIG -- cfg_page_0.asm -------------------------------------------

MSG_VEC       = $50    	 		        ; $50 Message to print
FUNC_RES_L    = MSG_VEC + 2         ; $52 For 16-bit subroutine results. Must be
FUNC_RES_H    = FUNC_RES_L + 1      ; $53 in zero page.

TBL_VEC_L     = FUNC_RES_H + 1      ; $54 Table vector - for searching tables
TBL_VEC_H     = TBL_VEC_L + 1       ; $55
TMP_ADDR_A    = TBL_VEC_H + 1       ; $56 Temp 2-byte vector/store for address
TMP_ADDR_A_L  = TMP_ADDR_A	        ; $56 - Alias -
TMP_ADDR_A_H  = TMP_ADDR_A + 1      ; $57
TMP_ADDR_B    = TMP_ADDR_A_H + 1    ; $58 Temp 2-byte vector/store for address
TMP_ADDR_B_L  = TMP_ADDR_B	        ; $58 - Alias -
TMP_ADDR_B_H  = TMP_ADDR_B + 1      ; $59
FILE_ADDR     = TMP_ADDR_B_H + 1    ; $5A
LOMEM         = FILE_ADDR + 2       ; $5C First available byte after user prog

STDIN_STATUS_REG = LOMEM + 2	      ; $5E Used to store various flags
PROC_REG = STDIN_STATUS_REG + 1  	  ; $5F Process flags
TIMER_STATUS_REG = PROC_REG + 1	    ; $60 Timer status register
