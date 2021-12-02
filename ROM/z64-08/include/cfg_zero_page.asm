; ZERO PAGE CONFIG -- cfg_zero_page.asm ----------------------------------------
; v07 - 07 Nov 2021
;
; Zero-page addresses
TEST_VAL    = $50

FUNC_RESULT = $60   ; to hold the result of a subroutine
FUNC_RES_L  = FUNC_RESULT+1   ; for 16-bit subroutine results
FUNC_RES_H  = FUNC_RES_L+1
BYTE_CONV_L = FUNC_RES_H+1   ; scratch space for converting bytes between num & string
BYTE_CONV_H = BYTE_CONV_L+1
BUF_PTR     = BYTE_CONV_H+1   ; multi-purpose buffer pointer

MSG_VEC     = $70   ; Message to be printed. LSB is MSG_VEC, MSB is +1
TBL_VEC_L   = MSG_VEC+1   ; table vector - for searching tables
TBL_VEC_H	= TBL_VEC_L+1
TMP_ADDR_A  = TBL_VEC_H+1
TMP_ADDR_B  = TMP_ADDR_A+2
; = TMP_ADDR_B + 2