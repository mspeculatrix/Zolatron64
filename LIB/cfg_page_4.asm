; Addresses for PAGE 4 - buffers and misc storage locations

STR_BUF_SZ = $20            ; 32 bytes

\ The purpose of the following variables is to provide tempoary storage within
\ subroutines/functions, as entry parameters for functions or to hold the
\ results of functions. You should not assume they have any reliable value
\ outside of functions other than immediate return values.
EXTMEM_BANK = $0400                   ; Number of current extended memory bank
TEST_VAL    = EXTMEM_BANK + 1
TMP_VAL     = TEST_VAL + 1
TMP_IDX     = TMP_VAL + 1             ; Index for use with buffers, loops
TMP_COUNT   = TMP_IDX + 1             ; For misc temporary counters
TMP_WORD_L  = TMP_COUNT + 1           ; For temporary storage of 16-bit values
TMP_WORD_H  = TMP_WORD_L + 1

FUNC_PARAM  = TMP_WORD_H + 1
FUNC_PARAM_L = FUNC_PARAM	            ; Alias
FUNC_PARAM_H = FUNC_PARAM_L + 1

BYTE_CONV_L = FUNC_PARAM_H + 1        ; For converting bytes between num & str
BYTE_CONV_H = BYTE_CONV_L + 1

STR_BUF = BYTE_CONV_H + 1

\ MATH STUFF
RAND_SEED    = STR_BUF + STR_BUF_SZ + 1	; 2-byte random seed number
UINT16_A     = RAND_SEED + 2
MATH_TMP16   = UINT16_A                   ; Alias
MATH_TMP_A   = UINT16_A			              ; Alias
MATH_TMP_B   = MATH_TMP_A + 2
UINT16_B	 = MATH_TMP_B + 1
UINT32_A     = UINT16_B + 2
UINT32_B     = UINT32_A + 4
UINT32_RES64 = UINT32_B + 4             ; Allow 8 bytes for this
UINT32_RES   = UINT32_RES64 + 8

PRG_EXIT_CODE = UINT32_RES + 2

; Stream Select Register
STREAM_SELECT_REG = PRG_EXIT_CODE + 1

;LCDV_TIMER_COUNT = STREAM_SELECT_REG + 1
;LCDV_TIMER_INTVL = LCDV_TIMER_COUNT + 2
; Synonyms for above
SYS_TIMER_COUNT = STREAM_SELECT_REG + 1   ; times timer interrupt has triggered
SYS_TIMER_INTVL = SYS_TIMER_COUNT + 2     ; value for interval - 2 bytes

LCD_BUF  = SYS_TIMER_INTVL + 2   ; next will be LCD_BUF + LCD_BUF_SZ + 1
