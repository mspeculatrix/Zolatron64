; VIA A & LCD CONFIG -- cfg_via_lcd.asm ------------------------------------------
;
; VIA A is at $A000 and is used for the LCD and system LEDs.
; Timer 1 is used for the delay function.
; Even if we stop using the LCD and LEDs, this VIA should be reserved for
; 'system' uses.
; Port B is used for the Data pins on the LCD display.
; Three pins on Port A are used for signal pins on the LCD:
; - PA5	RS		Register select
;	- PA6	RW		Read/Write
;	- PA7	E		  Execute
; Remaining pins on Port A are used for the 5 LEDs.

VIAA_BASE_ADDR = $A000

; 6522 VIA register addresses
VIAA_PORTA = VIAA_BASE_ADDR + $01     ; VIA Port A data/instruction register
VIAA_DDRA  = VIAA_BASE_ADDR + $03     ; Port A Data Direction Register
VIAA_PORTB = VIAA_BASE_ADDR + $00     ; VIA Port B data/instruction register
VIAA_DDRB  = VIAA_BASE_ADDR + $02     ; Port B Data Direction Register

; TIMER SETTINGS
VIAA_T1CL  = VIAA_BASE_ADDR + $04     ; Timer 1 counter low
VIAA_T1CH  = VIAA_BASE_ADDR + $05	    ; Timer 1 counter high
VIAA_T2CL  = VIAA_BASE_ADDR + $08     ; Timer 2 counter low
VIAA_T2CH  = VIAA_BASE_ADDR + $09	    ; Timer 2 counter high
VIAA_ACL   = VIAA_BASE_ADDR + $0B	    ; Auxiliary Control register
VIAA_IER   = VIAA_BASE_ADDR + $0E 	  ; Interrupt Enable Register
VIAA_IFR   = VIAA_BASE_ADDR + $0D	    ; Interrupt Flag Register
