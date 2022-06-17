\ cfg_flash-io-snd.asm

FIOS_BASE_ADDR = $BFC0		                ; For Sound VIA
; Register addresses
FIOS_DATA_PORT = FIOS_BASE_ADDR + $01     ; VIA Port A data/instruction register
FIOS_DATA_DDR  = FIOS_BASE_ADDR + $03     ; Port A Data Direction Register
FIOS_CTRL_PORT = FIOS_BASE_ADDR + $00     ; VIA Port B data/instruction register
FIOS_CTRL_DDR  = FIOS_BASE_ADDR + $02     ; Port B Data Direction Register

FIOS_T1CL  = FIOS_BASE_ADDR + $04         ; Timer 1 counter low
FIOS_T1CH  = FIOS_BASE_ADDR + $05	        ; Timer 1 counter high
FIOS_T2CL  = FIOS_BASE_ADDR + $08         ; Timer 2 counter low
FIOS_T2CH  = FIOS_BASE_ADDR + $09	        ; Timer 2 counter high
FIOS_ACL   = FIOS_BASE_ADDR + $0B		      ; Auxiliary Control register
FIOS_IER   = FIOS_BASE_ADDR + $0E 	      ; Interrupt Enable Register
FIOS_IFR   = FIOS_BASE_ADDR + $0D		      ; Interrupt Flag Register

FL_SLOT_SEL  = $BFE0        ; Write to this address to select memory slot (0-15)
FLASHMEM_LOC = $8000        ; This is where Flash memory lives
