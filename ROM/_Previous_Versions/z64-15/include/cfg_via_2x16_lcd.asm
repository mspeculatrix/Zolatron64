; VIA & LCD CONFIG -- cfg_via_lcd.asm ------------------------------------------
;
; VIA A is at $A000 and is used for the LCD.
;
; Port B is used for the Data pins on the LCD display.
; Three pins on Port A are used for signal pins on the LCD:
; - PA5	RS		Register select
;	- PA6	RW		Read/Write
;	- PA7	E		  Execute
;

VIAA_BASE_ADDR = $A000

; 6522 VIA register addresses
VIAA_PORTA = VIAA_BASE_ADDR + $01     ; VIA Port A data/instruction register
VIAA_DDRA  = VIAA_BASE_ADDR + $03     ; Port A Data Direction Register
VIAA_PORTB = VIAA_BASE_ADDR + $00     ; VIA Port B data/instruction register
VIAA_DDRB  = VIAA_BASE_ADDR + $02     ; Port B Data Direction Register

; TIMER SETTINGS for the delay function
VIAA_T1CL  = VIAA_BASE_ADDR + $04     ; timer 1 counter low
VIAA_T1CH  = VIAA_BASE_ADDR + $05	    ; timer 1 counter high
VIAA_ACL   = VIAA_BASE_ADDR + $0B	    ; Auxiliary Control register
VIAA_IER   = VIAA_BASE_ADDR + $0E 	  ; Interrupt Enable Register
VIAA_IFR   = VIAA_BASE_ADDR + $0D	    ; Interrupt Flag Register

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
