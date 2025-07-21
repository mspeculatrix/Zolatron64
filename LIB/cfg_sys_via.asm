\ SYSTEM VIA CONFIG -- cfg_sys_via.asm ------------------------------------------
\
\ These addresses are the same as those for the LCD panel, in
\ cfg_4x20_lcd.cfg
\
\ I'm creating these synonyms in case I want to remove the LCD at some point.
\ The Zolatron should always have a 65C22 VIA at this address.

SYSV_BASE_ADDR = $A000

; 6522 VIA register addresses
SYSV_PORTA = SYSV_BASE_ADDR + $01     ; VIA Port A data/instruction register
SYSV_DDRA  = SYSV_BASE_ADDR + $03     ; Port A Data Direction Register
SYSV_PORTB = SYSV_BASE_ADDR + $00     ; VIA Port B data/instruction register
SYSV_DDRB  = SYSV_BASE_ADDR + $02     ; Port B Data Direction Register

; TIMER SETTINGS
SYSV_T1CL  = SYSV_BASE_ADDR + $04     ; Timer 1 counter low
SYSV_T1CH  = SYSV_BASE_ADDR + $05	    ; Timer 1 counter high
SYSV_T2CL  = SYSV_BASE_ADDR + $08     ; Timer 2 counter low
SYSV_T2CH  = SYSV_BASE_ADDR + $09	    ; Timer 2 counter high
SYSV_ACR   = SYSV_BASE_ADDR + $0B	    ; Auxiliary Control register
SYSV_IER   = SYSV_BASE_ADDR + $0E 	  ; Interrupt Enable Register
SYSV_IFR   = SYSV_BASE_ADDR + $0D	    ; Interrupt Flag Register