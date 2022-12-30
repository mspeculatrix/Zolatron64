; cfg_uart_SC28L92_dual.asm
; For NXP SC28L92 dual UART.

SC28L92_BASE_ADDR = $B400

; OUTPUT PORT
; -- Presented on serial ports
; OP0 - RTSA
; OP1 - RTSB
; -- Presented on Output port - all can be used as general-purpose output ports,
; -- but list below also shows special functions
; OP2 - Channel A transmitter clock out (1x, 16x)
; OP3 - Active low counter/timer output; Channel B clock transmitter
; OP4 - RXA_INT
; OP5 - RXB_INT
; OP6 - TXA_INT
; OP7 - TXB_INT
; The output port (OP) is controlled by these registers:
; OPCR       - Controls source of date for OP ports 2-7. A 0 sets a pin as
;              general-purpose output while a 1 selects its special function.
; OPR        - Port register: set using command 0xE, reset with 0xF.
; MR/CR      - Sets source of data for OP0/OP1 (if OPR, then bits are inverted)
; SOPR       - Writing to this register changes the bits in the OPR. Only the
;              bits that are ones have an effect (writing ones to the same
;              positions in the OPR). Bits that are 0 have no effect. In other
;              words, a byte written here will be ORed with the contents of OPR.
; ROPR       - Writing to this resets the contents of OPR. Like SOPR, only bits
;              that are 1s will have an effect, settings the corresponding bits
;              in OPR to be set to 0 - 0s have no effect.
; NB: The actual output from the port is the *complement* of the OPR. So if a
; bit in the OPR is HIGH, then the pin is set LOW, and vice versa.

; Bit constants
SC28L92_OP2 = %00000100
SC28L92_OP3 = %00001000
SC28L92_OP4 = %00010000
SC28L92_OP5 = %00100000
SC28L92_OP6 = %01000000
SC28L92_OP7 = %10000000

SC28L92_IP2 = %00000100
SC28L92_IP3 = %00001000
SC28L92_IP4 = %00010000
SC28L92_IP5 = %00100000
SC28L92_IP6 = %01000000


; Registers for GENERAL operations
SC28L92_MRA       = SC28L92_BASE_ADDR           ; $00 Mode Register A
SC28L92_MRB       = SC28L92_BASE_ADDR + %1000   ; $08 Mode Register B
SC28L92_ACR       = SC28L92_BASE_ADDR + %0100   ; $04 Auxiliary Control Register
SC28L92_IMR       = SC28L92_BASE_ADDR + %0101   ; $05 Interrupt mask register
SC28L92_ISR       = SC28L92_BASE_ADDR + %0101   ; $05 Interrupt status register

; Registers for READ operations - /RD_EN = 0
SC28L92_SRA       = SC28L92_BASE_ADDR + %0001 ; $01 Status Register A
SC28L92_RxFIFOA   = SC28L92_BASE_ADDR + %0011 ; $03 RX Holding Register A
SC28L92_IPCR      = SC28L92_BASE_ADDR + %0100 ; $04 Input Port Change Register
SC28L92_CTU       = SC28L92_BASE_ADDR + %0110 ; $06 Counter/Timer Upper
SC28L92_CTL       = SC28L92_BASE_ADDR + %0111 ; $07 Counter/Timer Lower
SC28L92_SRB       = SC28L92_BASE_ADDR + %1001 ; $09 Status Register B
SC28L92_RxFIFOB   = SC28L92_BASE_ADDR + %1011 ; $0B RX Holding Register B
SC28L92_MISC_R    = SC28L92_BASE_ADDR + %1100 ; $0C Miscellaneous register
SC28L92_IPR       = SC28L92_BASE_ADDR + %1101 ; $0D Input Port Register
SC28L92_STRT_CNTR = SC28L92_BASE_ADDR + %1110 ; $0E Start counter command
SC28L92_STOP_CNTR = SC28L92_BASE_ADDR + %1111 ; $0F Stop counter command

; Registers for WRITE operations - /WR_EN = 0
SC28L92_CSRA      = SC28L92_BASE_ADDR + %0001 ; $01 Clock Select Register A
SC28L92_CRA       = SC28L92_BASE_ADDR + %0010 ; $02 Command Register A
SC28L92_TxFIFOA   = SC28L92_BASE_ADDR + %0011 ; $03 TX Holding Register A
SC28L92_CTPU      = SC28L92_BASE_ADDR + %0110 ; $06 C/T Upper Preset Register
SC28L92_CTPL      = SC28L92_BASE_ADDR + %0111 ; $07 C/T Lower Preset Register
SC28L92_CSRB      = SC28L92_BASE_ADDR + %1001 ; $09 Clock Select Register B
SC28L92_CRB       = SC28L92_BASE_ADDR + %1010 ; $02 Command Register B
SC28L92_TxFIFOB   = SC28L92_BASE_ADDR + %1011 ; $03 TX Holding Register B
SC28L92_OPCR      = SC28L92_BASE_ADDR + %1101 ; $0D Output Port Config Register
SC28L92_SOPR      = SC28L92_BASE_ADDR + %1110 ; $0E Set Output Ports Bits cmd
SC28L92_ROPR      = SC28L92_BASE_ADDR + %1111 ; $0F Reset Output Ports Bits cmd

; Test/Mask Bits
SC28L92_TxEMPT    = %00001000
SC28L92_TxRDY     = %00000100
SC28L92_RxFULL    = %00000010
SC28L92_RxRDY     = %00000001

;DUARTA_RX_BUF    = $0400 ; Serial RX buffer start address
;DUARTA_TX_BUF    = $0480 ; Serial TX buffer start address
;DUARTA_RX_IDX    = $047F ; Location of RX buffer index
;DUARTA_TX_IDX    = $04FF ; Location of TX buffer index
;DUARTA_BUF_LEN   = 120   ; Size of buffers. Actually have 127 bytes available
;DUARTA_BUF_MAX   = 127   ; but this leaves some headroom.

; UART FLAGS & MASKS for use with UART_STATUS_REG
;STDIN_NUL_RCVD_FLG = %00000001    ; Defined in cfg_main.asm
;STDIN_DAT_RCVD_FLG = %00000010    ;  ""
;STDIN_BUF_FULL_FLG = %00000100    ;  ""
;STDIN_CLEAR_FLAGS  = %11110000    ;  ""

; Synonyms for the STDIN flags above. As we're using Port A as the main
; console port now, probably better to use the generic STDIN_ constants.
DUART_RxA_NUL_RCVD_FL  = %00000001		; We've received a nul byte
DUART_RxA_DAT_RCVD_FL  = %00000010		; We've transferred data to our buffer
DUART_RxA_BUF_FULL_FL  = %00000100		; The buffer is full.
DUART_RxA_CLR_FLAGS    = %11110000      ; AND with reg to clear input flags

DUART_RxB_NUL_RCVD_FL  = %00010000		; We've received a nul byte
DUART_RxB_DAT_RCVD_FL  = %00100000		; We've transferred data to our buffer
DUART_RxB_BUF_FULL_FL  = %01000000		; The buffer is full.
DUART_RxB_CLR_FLAGS    = %00001111      ; AND with reg to clear input flags

; AND following with SC28L92_ISR to see if data received
DUART_RxA_RDY_MASK     = %00000010 		; SC28L92 has data in RX A FIFO
DUART_RxB_RDY_MASK     = %00100000 		; SC28L92 has data in RX B FIFO

; These baud rates work in Normal mode (bit 0 of MR0A/MR0B set to 0) and with
; bit 7 of ACR set to 0.
DUART_BAUD_300   = %01000100 			; Also works with ACR bit 7 set to 1
DUART_BAUD_1200  = %01100110 			; Also works with ACR bit 7 set to 1
DUART_BAUD_2400  = %10001000 			; Also works with ACR bit 7 set to 1
DUART_BAUD_4800  = %10011001 			; Also works with ACR bit 7 set to 1
DUART_BAUD_7200  = %10101010
DUART_BAUD_9600  = %10111011 			; Also works with ACR bit 7 set to 1
; These baud rates work in Normal mode with bit 7 of ACR set to 1.
DUART_BAUD_19200 = %11011000
