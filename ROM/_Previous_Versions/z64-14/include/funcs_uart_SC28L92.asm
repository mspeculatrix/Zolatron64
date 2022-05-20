\\ funcs_uart_SC28L92.asm

.uart_SC28L92_init
  pha
  lda #%10110000      ; To set MR pointer to 0
  sta SC28L92_CRA     ; Need some clock cycles to pass, so write to lower bits.
  lda #%00000100      ; Enable TX
  sta SC28L92_CRA 
  lda #%00000001      ; Enable RX
  sta SC28L92_CRA 
  ; TRY COMBINING THE ABOVE COMMANDS/SETTINGS
  lda #%10011000      ; RX watchdog on, 1-byte fill level for RX interrupts,
  sta SC28L92_MRA     ; 16 bytes for TX int, 16-byte FIFO, baudrate mode normal.
  lda #%00010000      ; To set MR pointer to MR1A
  sta SC28L92_CRA
  nop                 ; 2 nops = 4 cycles
  nop                 ; DON'T THINK THESE ARE NEEDED
  lda #%00010011  ; No RTS, 1-byte fill level for RX interrupts, char err mode,
  sta SC28L92_MRA ; no parity, 8 bits per char - MR pointer gets set to MR2A.
  lda #%00000111  ; 1 stop bit
  sta SC28L92_MRA
  \\ Set baud rate - assuming normal, not extended, mode
  lda #%10000000              ; Set baud rate generator select bit to 1
  sta SC28L92_ACR
  lda #%10111011              ; Receive and transmit at 9600
  ;lda #%11011000             ; Receive and transmit at 19200
  sta SC28L92_CSRA
  \\ Set interrupt mask register. Determines which events produce interrupts
  lda #%00000010              ; Enable interrupts on RX on port A
  sta SC28L92_IMR
  pla
  rts

.uart_SC28L92_println
  pha : phy
  ldy #0                          ; Set message offset to 0
.uart_SC28L92_println_chr
  jsr uart_SC28L92_wait_send_clr  ; Wait for serial port to be ready
  lda (MSG_VEC),Y                 ; Load next char
  beq uart_SC28L92_println_end    ; If char is 0, we've finished
  sta SC28L92_TxFIFOA             ; Write to data register. This sends the byte.
  iny                             ; Increment index
  jmp uart_SC28L92_println_chr    ; Go back for next character
.uart_SC28L92_println_end
  lda #CHR_LINEEND
  sta SC28L92_TxFIFOA
  ply : pla
  rts

.uart_SC28L92_wait_send_clr
  pha
.uart_SC28L92_wait_loop
  lda SC28L92_SRA                       ; Load the status register
  and #SC28L92_TxRDY                    ; Check the FIFO NOT FULL bit
  beq uart_SC28L92_wait_loop            ; If not set, loop...
  pla
  rts

.uart_SC28L92_test_msg
  pha
  lda #<test_msg
  sta MSG_VEC
  lda #>test_msg
  sta MSG_VEC+1
  jsr uart_SC28L92_println
  pla
  rts

