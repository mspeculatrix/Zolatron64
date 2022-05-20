; Addresses for PAGE 5 - buffers and misc storage locations
LCD_BUF_SZ = $28					  ; 40 bytes
TMP_BUF_SZ = $20                      ; 32 bytes
STR_BUF_SZ = $20                      ; 32 bytes

LCD_BUF0 = $0500
LCD_BUF1 = LCD_BUF0 + LCD_BUF_SZ
LCD_BUF2 = LCD_BUF1 + LCD_BUF_SZ
LCD_BUF3 = LCD_BUF2 + LCD_BUF_SZ
TMP_BUF = LCD_BUF3  + LCD_BUF_SZ      ; general-purpose buffer/scratchpad
TMP_IDX = TMP_BUF + TMP_BUF_SZ + 1    ; index for use with buffer
TMP_OFFSET = TMP_IDX + 1
TMP_COUNT = TMP_OFFSET + 1            ; for misc temporary counters
;TMP_CHR = TMP_COUNT + 1
STR_BUF = TMP_COUNT + 1               ; another general-purpose buffer
LOOP_COUNT = STR_BUF + STR_BUF_SZ + 1 ; general-purpose loop counter
TMP_WORD_L  = LOOP_COUNT+1		      ; for temporary storage of 16-bit values
TMP_WORD_H  = TMP_WORD_L+1
