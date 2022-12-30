\ funcs_duart.asm

\ ------------------------------------------------------------------------------
\ ---  DUART_INIT  -  Initialise DUART
\ ------------------------------------------------------------------------------
\ A - P
\ X - n/a
\ Y - n/a
.duart_init
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
  lda #%00010011  ; No RTS, 1-byte fill level for RX interrupts, char err mode,
  sta SC28L92_MRA ; no parity, 8 bits per char - MR pointer gets set to MR2A.
  lda #%00000111  ; 1 stop bit
  sta SC28L92_MRA
  \\ Set baud rate. Not using extended modes
  lda SC28L92_ACR
  ;and #%01111111                  ; Set baud rate generator select bit (7) to 0
  ora #%10000000                  ; Set baud rate generator select bit (7) to 1
  sta SC28L92_ACR
  ;lda #DUART_BAUD_4800            ; Receive and transmit rate
  lda #DUART_BAUD_9600            ; Receive and transmit rate
  ;lda #DUART_BAUD_19200            ; Receive and transmit rate
  sta SC28L92_CSRA
  \\ Set interrupt mask register. Determines which events produce interrupts
  lda #%00000010                  ; Enable interrupts on RX on port A
  sta SC28L92_IMR
  \\ Set Output Port
  lda #0
  sta SC28L92_OPCR                ; Set bits 2-7 of OP to gen-purpose outputs
  lda #%11111100
  sta SC28L92_SOPR                ; Reset all pins to LOW.
  pla
  rts

.duart_wait_send_clr
\ A - P
\ X - n/a
\ Y - n/a
  pha
.duart_wait_loop
  lda SC28L92_SRA                 ; Load the status register
  and #SC28L92_TxRDY              ; Check the FIFO NOT FULL bit
  beq duart_wait_loop             ; If not set, loop...
  pla
  rts

\ ******************************************************************************
\ ***  OS API FUNCTIONS
\ ******************************************************************************

\ ------------------------------------------------------------------------------
\ ---  DUART_PRINTLN
\ ---  Implements: OSWRMSG
\ ------------------------------------------------------------------------------
\ ON ENTRY: Vector address to message string must be in MSG_VEC, MSG_VEC+1
\ A - P
\ X - n/a
\ Y - P
.duart_println
  pha : phy
  ldy #0                          ; Set message offset to 0
.duart_println_chr
  lda (MSG_VEC),Y                 ; Load next char
  beq duart_println_end           ; If char is 0, we've finished
  jsr duart_wait_send_clr         ; Wait for serial port to be ready
  sta SC28L92_TxFIFOA             ; Write to data register. This sends the byte
  iny                             ; Increment index
  beq duart_println_inc_addr      ; Y has rolled over so update vector
  jmp duart_println_chr           ; Go back for next character
.duart_println_inc_addr
  inc MSG_VEC + 1                 ; Increment high byte
  jmp duart_println_chr           ; Go back for next character
.duart_println_end
  ply : pla
  rts

\ ------------------------------------------------------------------------------
\ ---  DUART_SND_STRBUF
\ ---  Implements: OSWRSBUF
\ ------------------------------------------------------------------------------
\ ON ENTRY: Text to be send must be in STR_BUF and mul-terminated.
\ A - P
\ X - n/a
\ Y - n/a
.duart_snd_strbuf
  pha
  lda #<STR_BUF                              ; LSB of message
  sta MSG_VEC
  lda #>STR_BUF                              ; MSB of message
  sta MSG_VEC+1
  jsr duart_println
  pla
  rts

\ ------------------------------------------------------------------------------
\ ---  DUART_SENDBUF
\ ---  Implements: OSWRBUF
\ ------------------------------------------------------------------------------
\ Sends contents of STDOUT_BUF buffer.
\ ON ENTRY: Text to be send must be in STDOUT_BUF and nul-terminated.
\ A - O
\ X - O
\ Y - n/a
.duart_sendbuf
  ldx #0                           ; Offset index
 .duart_sendbuf_next_char
  lda STDOUT_BUF,X                 ; Load next char
  beq duart_sendbuf_end            ; If char is 0, we've finished
  jsr duart_wait_send_clr          ; Wait until DUART is ready for another byte
  sta SC28L92_TxFIFOA              ; Write to Data Reg. This sends the byte
  inx                              ; Increment offset index
  cpx STDOUT_IDX                   ; Check if we're at the buffer index
  beq duart_sendbuf_end            ; If so, end it here
  cpx #STR_BUF_LEN                 ; Check against max size, to prevent overrun
  beq duart_sendbuf_end            ; If so, end it here
  jmp duart_sendbuf_next_char      ; Otherwise do the next char
.duart_sendbuf_end
  ;stz STDOUT_IDX                   ; Re-zero the index
  rts

\ ------------------------------------------------------------------------------
\ ---  DUART_SENDCHAR
\ ---  Implements: OSWRCH
\ ------------------------------------------------------------------------------
\ Write a single character to out stream.
\ ON ENTRY: Char must be in A.
\ A - P
\ X - n/a
\ Y - n/a
.duart_sendchar
  jsr duart_wait_send_clr          ; Wait until DUART is ready for another byte
  sta SC28L92_TxFIFOA              ; Write to Data Reg. This sends the byte
  rts

\ ------------------------------------------------------------------------------
\ ---  DUART_WRITEOP
\ ---  Implements: OSWROP
\ ------------------------------------------------------------------------------
\ Set a specific pin on the output port high or low.
\ ON ENTRY: - A must contain value (0 or 1) to be set
\           - X must contain pin number constant - eg, SC28L92_OP2
\ NB: The actual output from the port is the *complement* of the OPR. So if a
\     bit in the OPR is HIGH, then the pin is set LOW, and vice versa.
\ A - O
\ X - P
\ Y - n/a
.duart_writeOP
  cmp #0
  beq duart_writeOP_zero
  txa
  sta SC28L92_ROPR            ; Reset OPR bit to 0, pin to HIGH
  jmp duart_writeOP_done
.duart_writeOP_zero
  txa
  sta SC28L92_SOPR            ; Set OPR bit to 1, pin to LOW
.duart_writeOP_done
  rts
