; cfg_uart_SC28L92_dual.asm
; For NXP SC28L92 dual UART.

SC28L92_BASE_ADDR = $BC00

; Registers for GENERAL operations
SC28L92_MRA       = SC28L92_BASE_ADDR           ; $00 Mode Register A
SC28L92_MRB       = SC28L92_BASE_ADDR + %1000   ; $08 Mode Register B
SC28L92_ACR       = SC28L92_BASE_ADDR + %0100   ; $04 Auxiliary Control Register
SC28L92_IMR       = SC28L92_BASE_ADDR + %0101   ; $05 Interrupt mask register
SC28L92_ISR       = SC28L92_BASE_ADDR + %0101   ; $05 Interrupt status register

; Registers for READ operations - /RD_EN = 0
SC28L92_SRA       = SC28L92_BASE_ADDR + %0001   ; $01 Status Register A
SC28L92_RxFIFOA   = SC28L92_BASE_ADDR + %0011   ; $03 RX Holding Register A
SC28L92_IPCR      = SC28L92_BASE_ADDR + %0100   ; $04 Input Port Change Register
SC28L92_CTU       = SC28L92_BASE_ADDR + %0110   ; $06 Counter/Timer Upper
SC28L92_CTL       = SC28L92_BASE_ADDR + %0111   ; $07 Counter/Timer Lower
SC28L92_SRB       = SC28L92_BASE_ADDR + %1001   ; $09 Status Register B
SC28L92_RxFIFOB   = SC28L92_BASE_ADDR + %1011   ; $0B RX Holding Register B
SC28L92_MISC_R    = SC28L92_BASE_ADDR + %1100   ; $0C Miscellaneous register
SC28L92_IPR       = SC28L92_BASE_ADDR + %1101   ; $0D Input Port Register
SC28L92_STRT_CNTR = SC28L92_BASE_ADDR + %1110   ; $0E Start counter command
SC28L92_STOP_CNTR = SC28L92_BASE_ADDR + %1111   ; $0F Stop counter command

; Registers for WRITE operations - /WR_EN = 0
SC28L92_CSRA      = SC28L92_BASE_ADDR + %0001   ; $01 Clock Select Register A
SC28L92_CRA       = SC28L92_BASE_ADDR + %0010   ; $02 Command Register A
SC28L92_TxFIFOA   = SC28L92_BASE_ADDR + %0011   ; $03 TX Holding Register A
SC28L92_CTPU      = SC28L92_BASE_ADDR + %0110   ; $06 C/T Upper Preset Register
SC28L92_CTPL      = SC28L92_BASE_ADDR + %0111   ; $07 C/T Lower Preset Register
SC28L92_CSRB      = SC28L92_BASE_ADDR + %1001   ; $09 Clock Select Register B
SC28L92_CRB       = SC28L92_BASE_ADDR + %1010   ; $02 Command Register B
SC28L92_TxFIFOB   = SC28L92_BASE_ADDR + %1011   ; $03 TX Holding Register B
SC28L92_OPCR      = SC28L92_BASE_ADDR + %1101   ; $0D Output Port Config Register
SC28L92_SOPR      = SC28L92_BASE_ADDR + %1110   ; $0E Set Output Ports Bits Command
SC28L92_ROPR      = SC28L92_BASE_ADDR + %1111   ; $0F Reset Output Ports Bits Command

; Test/Mask Bits
SC28L92_TxEMPT    = %00001000
SC28L92_TxRDY     = %00000100
SC28L92_RxFULL    = %00000010
SC28L92_RxRDY     = %00000001
