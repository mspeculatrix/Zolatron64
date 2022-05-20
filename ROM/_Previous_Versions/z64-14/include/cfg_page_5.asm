; Addresses for PAGE 5 - buffers and misc storage locations

TMP_BUF_SZ = $20            ; 32 bytes
STR_BUF_SZ = $20            ; 32 bytes
 
TMP_BUF = $0500                       ; general-purpose buffer/scratchpad
TMP_IDX = TMP_BUF + TMP_BUF_SZ + 1    ; index for use with buffer
TMP_OFFSET = TMP_IDX + 1
TMP_COUNT = TMP_OFFSET + 1            ; for misc temporary counters
STR_BUF = TMP_COUNT + 1               ; another general-purpose buffer
LOOP_COUNT = STR_BUF + STR_BUF_SZ + 1 ; general-purpose loop counter
TMP_WORD_L  = LOOP_COUNT+1		      ; for temporary storage of 16-bit values
TMP_WORD_H  = TMP_WORD_L+1
; Variables for holding multi-byte vaues for math routines such as
; comparing two numbers.
INT32uA = TMP_WORD_H + 1  	; 32-bit unsigned INT - 4 bytes
INT32uB = INT32uA + 4  	  	; 32-bit unsigned INT - 4 bytes
INT16uA = INT32uB + 4	    ; 16-bit unsigned INT - 2 bytes
INT16uB = INT16uA + 2	    ; 16-bit unsigned INT - 2 bytes

VIAA_TIMER_COUNT = INT16uB + 2            ; times timer interrupt has triggered
VIAA_TIMER_INTVL = VIAA_TIMER_COUNT + 2   ; value for interval - 2 bytes

VIAC_TIMER_COUNT = VIAA_TIMER_INTVL + 2   ; times timer interrupt has triggered
VIAC_TIMER_INTVL = VIAC_TIMER_COUNT + 2   ; value for interval - 2 bytes

BARLED = VIAC_TIMER_INTVL + 2				      ; for the bar LED display
BARLED_L = BARLED
BARLED_H = BARLED + 1

LCD_BUF  = BARLED + 2
; next will be LCD_BUF + LCD_BUF_SZ


