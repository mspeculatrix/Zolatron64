; 6551 ACIA SERIAL FUNCTIONS -- funcs_6551_acia.asm ----------------------------

\ ------------------------------------------------------------------------------
\ ---  ACIA_WAIT_SEND_CLR
\ ------------------------------------------------------------------------------
\ Pause until ACIA is able to receive more input. Blocking!
.acia_wait_send_clr
  pha                          ; Push A to stack to save it
.acia_wait_send_loop        
  lda ACIA_STAT_REG            ; Get contents of status register
  and #ACIA_TX_RDY_BIT         ; AND with ready bit
  beq acia_wait_send_loop      ; If it's zero, we're not ready yet
  pla                          ; Otherwise, recover A from stack
  rts

;.acia_wait_byte_recvd          ; not using this yet. Ever?
;  lda ACIA_STAT_REG            ; Possibly if I implement flow control
;  and #ACIA_RX_RDY_BIT
;  beq acia_wait_byte_recvd
;  rts

;.serial_send_hexval           ; assumes byte value is in A
;  pha : phx : phy             ; preserve registers
;  jsr byte_to_hex_str
;  lda #<TMP_BUF               ; Setting MSG_VEC to be the address of TMP_BUF
;  sta MSG_VEC                 ; but message is actually in STR_BUF
;  lda #>TMP_BUF               ; so is this right? I Think we should be using 
;  jsr acia_println          ; STR_BUF instead of TMP_BUF
;  ply : plx : pla ; restore registers
;  rts

\ ------------------------------------------------------------------------------
\ ---  ACIA_PRTERR
\ ------------------------------------------------------------------------------
\ ON ENTRY: Assumes error code in FUNC_ERR
.acia_prterr                 ; mainly for debugging
  pha
  lda FUNC_ERR
  jsr byte_to_hex_str
  jsr acia_prt_strbuf
  pla
  rts

\ ------------------------------------------------------------------------------
\ ---  ACIA_PRTPROMPT
\ ------------------------------------------------------------------------------
\ Print the standard prompt.
\ Should probably just replace this with the macro wherever it's used.
.acia_prtprompt
  PRT_MSG prompt_msg, acia_println
  rts

\ ------------------------------------------------------------------------------
\ ---  UART_6551_INIT
\ ------------------------------------------------------------------------------
\ Initialise 6551 ACIA
.uart_6551_init
  stz ACIA_STAT_REG             ; Reset ACIA
  stz STDIN_STATUS_REG          ; Also zero-out our status register
  stz STDIN_IDX                 ; Zero buffer index
  stz STDOUT_IDX                ; Zero buffer index
  stz PROC_REG                  ; Initialise process register
  lda #ACIA_8N1_9600            ; Set control register config - set speed & 8N1
  sta ACIA_CTRL_REG
  lda #ACIA_CMD_CFG             ; Set command register config
  sta ACIA_CMD_REG
  rts
  
\ ------------------------------------------------------------------------------
\ ---  OS API Functions
\ ------------------------------------------------------------------------------

\ ------------------------------------------------------------------------------
\ ---  ACIA_PRINTLN
\ ---  Implements: OSWRMSG
\ ------------------------------------------------------------------------------
\ ON ENTRY: Vector address to message string must be in MSG_VEC, MSG_VEC+1
.acia_println
  pha : phy
  ldy #0                       ; Set message offset to 0
.acia_println_chr
  lda (MSG_VEC),Y              ; Load next char
  beq acia_println_end         ; If char is 0, we've finished
  jsr acia_wait_send_clr       ; Wait for serial port to be ready
  sta ACIA_DATA_REG            ; Write to data register. This sends the byte
  iny                          ; Increment index
  beq acia_println_inc_addr    ; Y has rolled over so update vector        
  jmp acia_println_chr         ; Go back for next character
.acia_println_inc_addr
  inc MSG_VEC + 1              ; Increment high byte
  jmp acia_println_chr
.acia_println_end
  ply : pla
  rts

\ ------------------------------------------------------------------------------
\ ---  ACIA_PRT_STRBUF
\ ---  Implements: OSWRSBUF
\ ------------------------------------------------------------------------------
\ ON ENTRY: Text to be send must be in STR_BUF and mul-terminated.
.acia_prt_strbuf
  pha
  lda #<STR_BUF                              ; LSB of message
  sta MSG_VEC
  lda #>STR_BUF                              ; MSB of message
  sta MSG_VEC+1
  jsr acia_println
  pla
  rts

\ ------------------------------------------------------------------------------
\ ---  ACIA_SENDBUF
\ ---  Implements: OSWRBUF
\ ------------------------------------------------------------------------------
\ Sends contents of STDOUT_BUF buffer and clears it.
\ ON ENTRY: Text to be send must be in STDOUT_BUF and mul-terminated.
.acia_sendbuf
  ldx #0                          ; Offset index
 .acia_sendbuf_next_char
  lda STDOUT_BUF,X                ; Load next char
  beq acia_sendbuf_end            ; If char is 0, we've finished
  jsr acia_wait_send_clr          ; Wait until ACIA is ready for another byte
  sta ACIA_DATA_REG               ; Write to Data Reg. This sends the byte
  inx                             ; Increment offset index
  cpx STDOUT_IDX                  ; Check if we're at the buffer index
  beq acia_sendbuf_end            ; If so, end it here
  cpx #STR_BUF_LEN                ; Check against max size, to prevent overrun
  beq acia_sendbuf_end            ; If so, end it here
  jmp acia_sendbuf_next_char      ; Otherwise do the next char
.acia_sendbuf_end
  stz STDOUT_IDX                  ; Re-zero the index
  rts

\ ------------------------------------------------------------------------------
\ ---  ACIA_WRITECHAR
\ ---  Implements: OSWRCH
\ ------------------------------------------------------------------------------
\ Write a single character to out stream.
\ ON ENTRY: Char must be in A.
.acia_writechar
  jsr acia_wait_send_clr          ; Wait until ACIA is ready for another byte
  sta ACIA_DATA_REG               ; Write to Data Reg. This sends the byte
  rts

