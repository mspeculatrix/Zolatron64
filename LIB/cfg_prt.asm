\ PRINTER INTERFACE CONFIG
\ Timers are available for other uses.

\ The following are effectively synonyms of those defined in cfg_parallel.asm.
\ I'm defining specific constants for the printer port in case we want to,
\ for example, have more than one parallel port.
PRT_BASE_ADDR = $AC00
; Register addresses
PRT_DATA_PORT = PRT_BASE_ADDR + $01     ; VIA Port A data register
PRT_DATA_DDR  = PRT_BASE_ADDR + $03     ; Port A Data Direction Register
PRT_CTRL_PORT = PRT_BASE_ADDR + $00     ; VIA Port B control register
PRT_CTRL_DDR  = PRT_BASE_ADDR + $02     ; Port B Data Direction Register

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

PRT_STATE_OK      = 0
PRT_STATE_OFFLINE = 1
PRT_STATE_PE      = 2
PRT_STATE_ERR     = 3
PRT_STATE_CHKS    = 128           ; Times we'll check state before aborting

PRT_CTRL_PT_DIR  = %11010000      ; For DDR on control port
PRT_STROBE_DELAY = $10            ; Length of strobe in ms

MACRO PRT_PULSE_DELAY
  lda #PRT_STROBE_DELAY
  sta LCDV_TIMER_INTVL
  stz LCDV_TIMER_INTVL + 1
  jsr OSDELAY
ENDMACRO

;MACRO PRT_PULSE_STROBE
;  lda PRT_CTRL_PORT
;  and #PRT_STRB_ON
;  sta PRT_CTRL_PORT
;  PRT_PULSE_DELAY
;  lda PRT_CTRL_PORT
;  ora #PRT_STRB_OFF
;  sta PRT_CTRL_PORT
;ENDMACRO
