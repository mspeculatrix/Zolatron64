; 6522 VIA C
VIAC_BASE_ADDR = $A800

; register addresses
VIAC_PORTA = VIAC_BASE_ADDR + $01      ; VIA Port A data/instruction register
VIAC_DDRA  = VIAC_BASE_ADDR + $03      ; Port A Data Direction Register
VIAC_PORTB = VIAC_BASE_ADDR + $00      ; VIA Port B data/instruction register
VIAC_DDRB  = VIAC_BASE_ADDR + $02      ; Port B Data Direction Register
VIAC_T1CL  = VIAC_BASE_ADDR + $04      ; timer 1 counter low
VIAC_T1CH  = VIAC_BASE_ADDR + $05	     ; timer 1 counter high
VIAC_ACL   = VIAC_BASE_ADDR + $0B		   ; Auxiliary Control register
VIAC_IER   = VIAC_BASE_ADDR + $0E 	   ; Interrupt Enable Register
VIAC_IFR   = VIAC_BASE_ADDR + $0D		   ; Interrupt Flag Register
