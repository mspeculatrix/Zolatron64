\ LCD CONFIG -- cfg_2x16_lcd.asm -----------------------------------------------
\
\ Port B of the VIA is used for the Data pins on the LCD display.
\ Three pins on Port A are used for signal pins on the LCD:
\ - PA5	  RS		Register select
\	- PA6	  RW		Read/Write
\	- PA7	  E		  Execute
\ The other 5 pins - PA0-PA4  - are used for the LEDs.

LED_ERR      = 0
LED_BUSY	   = 1
LED_OK 		   = 2
LED_FILE_ACT = 3
LED_DEBUG 	 = 4

; LCD PANEL
LCD_LINES     = 2          ; number of lines on display
LCD_COLS      = 16         ; number of chars per line
LCD_LN_BUF_SZ = $28		     ; 40 bytes - per  line
LCD_BUF_SZ    = LCD_LINES * LCD_LN_BUF_SZ
LCD_MOVE_SRC  = 39		     ; for 2-line display
LCD_MOVE_DST  = 79
;LCD_MOVE_SRC  = 79		     ; for 4-line display
;LCD_MOVE_DST  = 119
LCD_CLS       = %00000001  ; Clear screen & reset display memory
LCD_TYPE      = %00111000  ; Set 8-bit mode; 2-line display; 5x8 font
LCD_MODE      = %00001100  ; Display on; cursor off; blink off
LCD_CURS_HOME = %00000010  ; return cursor to home position
LCD_CURS_L    = %00010000  ; shifts cursor to the left
LCD_CURS_R    = %00010100  ; shifts cursor to the right
LCD_EX = %10000000    ; Toggling this high enables execution of byte in register
LCD_RW = %01000000    ; Read/Write bit: 0 = read; 1 = write
LCD_RS = %00100000    ; Register select bit: 0 = instruction reg; 1 = data reg
LCD_BUSY_FLAG = %10000000 
LCD_SET_DDRAM = %10000000   ; to be ORed with a 7-bit value for the DDRAM address

; LEDs - LEDs 0-4 are on Port A, PA0-PA4
LED_MASK = %00011111        ; will be ORed with control bits for LCD on PORTA

MACRO LED_ON led_num
  pha
  lda VIAA_PORTA
  ora #1 << led_num
  sta VIAA_PORTA
  pla
ENDMACRO

MACRO LED_TOGGLE led_num
  pha
  lda VIAA_PORTA
  eor #1 << led_num
  sta VIAA_PORTA
  pla
ENDMACRO

MACRO LED_OFF led_num
  pha
  lda #255
  eor #(1 << led_num)
  and VIAA_PORTA
  sta VIAA_PORTA
  pla
ENDMACRO

MACRO LCD_SET_CTL ctl_bits        ; set control bits for LCD
  lda VIAA_PORTA                  ; load the current state or PORT A
  and #LED_MASK                   ; clear the top three bits
  ora #ctl_bits                   ; set those bits. Lower 5 bits should be 0s
  sta VIAA_PORTA                  ; store result
ENDMACRO
