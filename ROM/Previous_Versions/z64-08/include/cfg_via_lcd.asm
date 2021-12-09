; VIA & LCD CONFIG -- cfg_via_lcd.asm ------------------------------------------
; v07 - 05 Nov 2021
;
; 6522 VIA register addresses
VIA_A_PORTA = $A001     ; VIA Port A data/instruction register
VIA_A_DDRA  = $A003     ; Port A Data Direction Register
VIA_A_PORTB = $A000     ; VIA Port B data/instruction register
VIA_A_DDRB  = $A002     ; Port B Data Direction Register

; LCD PANEL
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
LCD_SET_DDRAM = %10000000  ; to be ORed with a 7-bit value for the DDRAM address
