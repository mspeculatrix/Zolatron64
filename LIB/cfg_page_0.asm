; ZERO PAGE CONFIG -- cfg_page_0.asm -------------------------------------------

MSG_VEC      = $50    	 		      ; Message to print. LSB is MSG_VEC, MSB is +1
FUNC_RES_L   = MSG_VEC + 2        ; For 16-bit subroutine results. Must be in
FUNC_RES_H   = FUNC_RES_L + 1     ; zero page.

TBL_VEC_L    = FUNC_RES_H + 1     ; Table vector - for searching tables
TBL_VEC_H	   = TBL_VEC_L + 1
TMP_ADDR_A   = TBL_VEC_H + 1      ; Temporary 2-byte vector/store for address
TMP_ADDR_A_L = TMP_ADDR_A	        ; - Alias -
TMP_ADDR_A_H = TMP_ADDR_A + 1
TMP_ADDR_B   = TMP_ADDR_A_H + 1   ; Temporary 2-byte vector/store for address
TMP_ADDR_B_L = TMP_ADDR_B	        ; - Alias -
TMP_ADDR_B_H = TMP_ADDR_B + 1
FILE_ADDR    = TMP_ADDR_B_H + 1

STDIN_STATUS_REG = FILE_ADDR + 2		; used to store various flags
PROC_REG = STDIN_STATUS_REG + 1  			; process flags
TIMER_STATUS_REG = PROC_REG + 1	      ; timer status register
