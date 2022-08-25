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
TMP_WORD_L  = TMP_COUNT + 1		        ; For temporary storage of 16-bit values
TMP_WORD_H  = TMP_WORD_L + 1

FUNC_PARAM  = TMP_WORD_H + 1
FUNC_PARAM_L = FUNC_PARAM	            ; Alias
FUNC_PARAM_H = FUNC_PARAM_L + 1
FUNC_RESULT = FUNC_PARAM_H + 1        ; To hold the 8-bit result of a subroutine
FUNC_ERR    = FUNC_RESULT + 1	        ; Store an error code for functions
BYTE_CONV_L = FUNC_ERR + 1            ; For converting bytes between num & str
BYTE_CONV_H = BYTE_CONV_L + 1

STR_BUF = BYTE_CONV_H + 1

MATH_TMP16  = STR_BUF + STR_BUF_SZ + 1
MATH_TMP_A  = MATH_TMP16			          ; Alias
MATH_TMP_B  = MATH_TMP_A + 2

PRG_EXIT_CODE = MATH_TMP_B + 2

; Stream Select Register
STREAM_SELECT_REG = PRG_EXIT_CODE + 1

LCDV_TIMER_COUNT = STREAM_SELECT_REG + 1  ; times timer interrupt has triggered
LCDV_TIMER_INTVL = LCDV_TIMER_COUNT + 2   ; value for interval - 2 bytes

LCD_BUF  = LCDV_TIMER_INTVL + 2   ; next will be LCD_BUF + LCD_BUF_SZ + 1


; Variables for holding multi-byte vaues for math routines such as
; comparing two numbers.
;INT32uA = STREAM_SELECT_REG + 1  	; 32-bit unsigned INT - 4 bytes
;INT32uB = INT32uA + 4  	  	      ; 32-bit unsigned INT - 4 bytes
;INT16uA = INT32uB + 4	            ; 16-bit unsigned INT - 2 bytes
;INT16uB = INT16uA + 2	            ; 16-bit unsigned INT - 2 bytes


;ZD_TIMER_COUNT = LCD_BUF + LCD_BUF_SZ  ; DEFINED IN cfg_VIAB_ZolaDOS.asm
