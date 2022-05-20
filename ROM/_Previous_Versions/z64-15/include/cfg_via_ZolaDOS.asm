; Configuration for ZolaDOS mass storage system.
; Uses a 6522 VIA at address $A400

; 6522 VIA register addresses
ZD_DATA_PORT = $A401     ; VIA Port A data/instruction register
ZD_DATA_DDR  = $A403     ; Port A Data Direction Register
ZD_CTRL_PORT = $A400     ; VIA Port B data/instruction register
ZD_CTRL_DDR  = $A402     ; Port B Data Direction Register

; PORT A is used for 8-bit parallel data.
; PORT B is used for control signals

; Control signals        VIA pin    function            6522          RPi
ZD_ACTIVE = %00001000     ; PB3	    interface active  - output        input
ZD_INP_DR = %00010000     ; PB4	    input data ready  - CA1 input     output
ZD_INP_DT = %00100000	    ; PB5     input data taken  - CA2 output    input
ZD_OUT_DR = %01000000	    ; PB6     output data ready - CB2 output    input
ZD_OUT_DT = %10000000     ; PB7     output data taken - CB1 input     output

ZD_DATA_SET_OUT = %11111111
ZD_DATA_SET_IN  = %00000000
ZD_CTRL_PINDIR  = %00010110
