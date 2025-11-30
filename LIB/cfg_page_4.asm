; Addresses for PAGE 4 - buffers and misc storage locations

STR_BUF_SZ = $20            ; 32 bytes

\ The purpose of the following variables is to provide tempoary storage within
\ subroutines/functions, as entry parameters for functions or to hold the
\ results of functions. You should not assume they have any reliable value
\ outside of functions other than immediate return values.
EXTMEM_BANK = $0400                   ; 1B No. current ext memory bank
TEST_VAL    = EXTMEM_BANK + 1         ; 1B
TMP_VAL     = TEST_VAL + 1            ; 1B
TMP_IDX     = TMP_VAL + 1             ; 1B Index for buffers, loops
TMP_COUNT   = TMP_IDX + 1             ; 1B For misc temporary counters
TMP_WORD_L  = TMP_COUNT + 1           ; 1B For temp storage of 16-bit vals
TMP_WORD_H  = TMP_WORD_L + 1          ; 1B

FUNC_PARAM  = TMP_WORD_H + 1          ; 1B
FUNC_PARAM_L = FUNC_PARAM	          ; (alias)
FUNC_PARAM_H = FUNC_PARAM_L + 1       ; 1B

BYTE_CONV_L = FUNC_PARAM_H + 1        ; 1B Convert bytes between num & str
BYTE_CONV_H = BYTE_CONV_L + 1         ; 1B

STR_BUF = BYTE_CONV_H + 1             ; 32B STR_BUF_SZ

\ MATH STUFF
RAND_SEED    = STR_BUF + STR_BUF_SZ   ; 2B random seed number
MATH_TMP_A   = RAND_SEED + 2          ; 1B
MATH_TMP_B   = MATH_TMP_A + 1         ; 1B
UINT16_A     = MATH_TMP_B + 1         ; 2B
MATH_TMP16   = UINT16_A               ; Alias
UINT16_B     = UINT16_A + 2           ; 2B
UINT32_A     = UINT16_B + 2           ; 4B
UINT32_B     = UINT32_A + 4           ; 4B
UINT32_RES64 = UINT32_B + 4           ; 8B
UINT32_RES   = UINT32_RES64 + 8       ; 2B

PRG_EXIT_CODE = UINT32_RES + 2        ; 1B

; Stream Select Register
STREAM_SELECT_REG = PRG_EXIT_CODE + 1 ; 1B

SYS_TIMER_COUNT = STREAM_SELECT_REG + 1 ; 2B no. times timer int has triggered
SYS_TIMER_INTVL = SYS_TIMER_COUNT + 2   ; 2B value for interval

LCD_BUF  = SYS_TIMER_INTVL + 2        ; LCD_BUF_SZ

; next will be LCD_BUF + LCD_BUF_SZ
