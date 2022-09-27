\ 6522 VIA D - PARALLEL PORT
\ Timers are available for other uses.
\ This provides generic constants for the parallel port - not tied to a
\ specific use, such as printing. It's likely that specific solutions might
\ use synonyms for these values (eg, see cfg_prt.asm).

PRLL_BASE_ADDR = $AC00

; Register addresses
PRLL_DATA_PORT = PRLL_BASE_ADDR + $01     ; VIA Port A data/instruction register
PRLL_DATA_DDR  = PRLL_BASE_ADDR + $03     ; Port A Data Direction Register
PRLL_CTRL_PORT = PRLL_BASE_ADDR + $00     ; VIA Port B data/instruction register
PRLL_CTRL_DDR  = PRLL_BASE_ADDR + $02     ; Port B Data Direction Register

PRLL_T1CL  = PRLL_BASE_ADDR + $04         ; Timer 1 counter low
PRLL_T1CH  = PRLL_BASE_ADDR + $05	        ; Timer 1 counter high
PRLL_T2CL  = PRLL_BASE_ADDR + $08         ; Timer 2 counter low
PRLL_T2CH  = PRLL_BASE_ADDR + $09	        ; Timer 2 counter high
PRLL_ACR   = PRLL_BASE_ADDR + $0B		      ; Auxiliary Control register
PRLL_IER   = PRLL_BASE_ADDR + $0E 	      ; Interrupt Enable Register
PRLL_IFR   = PRLL_BASE_ADDR + $0D		      ; Interrupt Flag Register
