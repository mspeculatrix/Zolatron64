\ 6522 VIA C - USER PORT
\ This VIA is intended to provide two 8-bit user ports as well as timers for
\ use by user programs.
VIAC_BASE_ADDR = $A800

; register addresses
VIAC_PORTA = VIAC_BASE_ADDR + $01       ; VIA Port A data/instruction register
VIAC_DDRA  = VIAC_BASE_ADDR + $03       ; Port A Data Direction Register
VIAC_PORTB = VIAC_BASE_ADDR + $00       ; VIA Port B data/instruction register
VIAC_DDRB  = VIAC_BASE_ADDR + $02       ; Port B Data Direction Register

VIAC_T1CL  = VIAC_BASE_ADDR + $04       ; timer 1 counter low
VIAC_T1CH  = VIAC_BASE_ADDR + $05	      ; timer 1 counter high
VIAC_T2CL  = VIAC_BASE_ADDR + $08       ; timer 2 counter low
VIAC_T2CH  = VIAC_BASE_ADDR + $09	      ; timer 2 counter high
VIAC_ACL   = VIAC_BASE_ADDR + $0B		    ; Auxiliary Control register
VIAC_IER   = VIAC_BASE_ADDR + $0E 	    ; Interrupt Enable Register
VIAC_IFR   = VIAC_BASE_ADDR + $0D		    ; Interrupt Flag Register

; ALIASES - eventually, these should replace the constants above
USRP_BASE_ADDR = $A800

USRP_PORTA = USRP_BASE_ADDR + $01       ; VIA Port A data/instruction register
USRP_DDRA  = USRP_BASE_ADDR + $03       ; Port A Data Direction Register
USRP_PORTB = USRP_BASE_ADDR + $00       ; VIA Port B data/instruction register
USRP_DDRB  = USRP_BASE_ADDR + $02       ; Port B Data Direction Register

USRP_T1CL  = USRP_BASE_ADDR + $04       ; timer 1 counter low
USRP_T1CH  = USRP_BASE_ADDR + $05	      ; timer 1 counter high
USRP_T2CL  = USRP_BASE_ADDR + $08       ; timer 2 counter low
USRP_T2CH  = USRP_BASE_ADDR + $09	      ; timer 2 counter high
USRP_ACL   = USRP_BASE_ADDR + $0B		    ; Auxiliary Control register
USRP_IER   = USRP_BASE_ADDR + $0E 	    ; Interrupt Enable Register
USRP_IFR   = USRP_BASE_ADDR + $0D		    ; Interrupt Flag Register

BARLED_CMD = USRP_PORTA	                ; These will be retired soon
BARLED_DAT = USRP_PORTB                 ; "
