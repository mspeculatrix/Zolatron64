\ 6522 VIA D - PARALLEL PORT
\ Timers are available for other uses.

PRT_BASE_ADDR = $AC00

; Register addresses
PRT_DATA_PORT = PRT_BASE_ADDR + $01     ; VIA Port A data/instruction register
PRT_DATA_DDR  = PRT_BASE_ADDR + $03     ; Port A Data Direction Register
PRT_CTRL_PORT = PRT_BASE_ADDR + $00     ; VIA Port B data/instruction register
PRT_CTRL_DDR  = PRT_BASE_ADDR + $02     ; Port B Data Direction Register

PRT_T1CL  = PRT_BASE_ADDR + $04         ; Timer 1 counter low
PRT_T1CH  = PRT_BASE_ADDR + $05	        ; Timer 1 counter high
PRT_T2CL  = PRT_BASE_ADDR + $08         ; Timer 2 counter low
PRT_T2CH  = PRT_BASE_ADDR + $09	        ; Timer 2 counter high
PRT_ACL   = PRT_BASE_ADDR + $0B		      ; Auxiliary Control register
PRT_IER   = PRT_BASE_ADDR + $0E 	      ; Interrupt Enable Register
PRT_IFR   = PRT_BASE_ADDR + $0D		      ; Interrupt Flag Register

; Printer signal masks 
; INPUTS: AND with PRT_CTRL_PORT to read state
PRT_SEL  = %00000001              ; PB0 - Input  - Active HIGH - Online
PRT_PE   = %00000010              ; PB1 - Input  - Active HIGH - Optional
PRT_BUSY = %00000100              ; PB2 - Input  - Active HIGH
PRT_ACK  = %00001000              ; PB3 - Input  - Active LOW
PRT_ERR  = %00100000              ; PB5 - Input  - Active LOW
; OUTPUTS: - AND the _ON masks with PRT_CTRL_PORT
;          - ORA the _OFF masks with PRT_CTRL_PORT
;          - store back in PRT_CTRL_PORT
PRT_INIT_ON  = %11101111          ; PB4 - Output - Active LOW
PRT_INIT_OFF = %00010000          ; PB4 - Output - Active LOW
PRT_AF_ON    = %10111111          ; PB6 - Output - Active LOW - Optional
PRT_AF_OFF   = %01000000
PRT_STRB_ON  = %01111111          ; PB7 - Output - Active LOW - 0.5-500µs pulse
PRT_STRB_OFF = %10000000

PRT_CTRL_PT_DIR  = %11010000      ; For DDR on control port
PRT_STROBE_DELAY = $0010          ; Length of strobe in ms

MACRO PRT_PULSE_DELAY
  lda #PRT_STROBE_DELAY
  sta LCDV_TIMER_INTVL
  lda #0
  sta LCDV_TIMER_INTVL + 1
  jsr OSDELAY
ENDMACRO

MACRO PRT_PULSE_STROBE
  lda PRT_CTRL_PORT
  and PRT_STRB_ON
  sta PRT_CTRL_PORT
  PRT_PULSE_DELAY
  lda PRT_CTRL_PORT
  ora PRT_STRB_OFF
  sta PRT_CTRL_PORT
ENDMACRO
