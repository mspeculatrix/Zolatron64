\\ funcs_duart.asm

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
;  nop                 ; 2 nops = 4 cycles
;  nop                 ; DON'T THINK THESE ARE NEEDED
  lda #%00010011  ; No RTS, 1-byte fill level for RX interrupts, char err mode,
  sta SC28L92_MRA ; no parity, 8 bits per char - MR pointer gets set to MR2A.
  lda #%00000111  ; 1 stop bit
  sta SC28L92_MRA
  \\ Set baud rate - assuming normal, not extended, mode
  lda #%10000000                  ; Set baud rate generator select bit to 1
  sta SC28L92_ACR
  lda #%10111011                  ; Receive and transmit at 9600
  ;lda #%11011000                 ; Receive and transmit at 19200
  sta SC28L92_CSRA
  \\ Set interrupt mask register. Determines which events produce interrupts
  lda #%00000010                  ; Enable interrupts on RX on port A
  sta SC28L92_IMR
  pla
  rts

.duart_wait_send_clr
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
.duart_println
  pha : phy
  ldy #0                          ; Set message offset to 0
.duart_println_chr
  lda (MSG_VEC),Y                 ; Load next char
  beq duart_println_end           ; If char is 0, we've finished
  jsr duart_wait_send_clr         ; Wait for serial port to be ready
  sta SC28L92_TxFIFOA             ; Write to data register. This sends the byte
  iny                             ; Increment index
  beq duart_println_inc_addr    ; Y has rolled over so update vector        
  jmp duart_println_chr           ; Go back for next character
.duart_println_inc_addr
  inc MSG_VEC + 1              ; Increment high byte
  jmp duart_println_chr           ; Go back for next character
.duart_println_end
  ply : pla
  rts

\ ------------------------------------------------------------------------------
\ ---  DUART_SND_STRBUF
\ ---  Implements: OSWRSBUF
\ ------------------------------------------------------------------------------
\ ON ENTRY: Text to be send must be in STR_BUF and mul-terminated.
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
\ Sends contents of STDOUT_BUF buffer and clears it.
\ ON ENTRY: Text to be send must be in STDOUT_BUF and nul-terminated.
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
  stz STDOUT_IDX                   ; Re-zero the index
  rts

\ ------------------------------------------------------------------------------
\ ---  DUART_SENDCHAR
\ ---  Implements: OSWRCH
\ ------------------------------------------------------------------------------
\ Write a single character to out stream.
\ ON ENTRY: Char must be in A.
.duart_sendchar
  jsr duart_wait_send_clr          ; Wait until DUART is ready for another byte
  sta SC28L92_TxFIFOA              ; Write to Data Reg. This sends the byte
  rts