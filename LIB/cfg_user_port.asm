\ 6522 VIA USER PORT
\ This VIA is intended to provide two 8-bit user ports as well as timers for
\ use by user programs. This used to be VIAC.

USRP_BASE_ADDR = $A800

USRP_PORTA = USRP_BASE_ADDR + $01       ; VIA Port A data/instruction register
USRP_DDRA  = USRP_BASE_ADDR + $03       ; Port A Data Direction Register
USRP_PORTB = USRP_BASE_ADDR + $00       ; VIA Port B data/instruction register
USRP_DDRB  = USRP_BASE_ADDR + $02       ; Port B Data Direction Register

USRP_DATA      = USRP_BASE_ADDR + $01   ; Synonyms for above just to be more
USRP_DATA_DDR  = USRP_BASE_ADDR + $03   ; specific in certain circumstances
USRP_CTRL      = USRP_BASE_ADDR + $00   ;  "
USRP_CTRL_DDR  = USRP_BASE_ADDR + $02   ;  "

USRP_T1CL  = USRP_BASE_ADDR + $04       ; Timer 1 counter low
USRP_T1CH  = USRP_BASE_ADDR + $05	      ; Timer 1 counter high
USRP_T2CL  = USRP_BASE_ADDR + $08       ; Timer 2 counter low
USRP_T2CH  = USRP_BASE_ADDR + $09	      ; Timer 2 counter high
USRP_ACR   = USRP_BASE_ADDR + $0B		    ; Auxiliary Control register
USRP_IER   = USRP_BASE_ADDR + $0E 	    ; Interrupt Enable Register
USRP_IFR   = USRP_BASE_ADDR + $0D		    ; Interrupt Flag Register
