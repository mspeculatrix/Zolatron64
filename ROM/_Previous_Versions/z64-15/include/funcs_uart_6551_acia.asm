; FUNCTIONS: SERIAL -- funcs_6551_acia.asm -------------------------------------
.uart_6551_init
  stz ACIA_STAT_REG     ; reset ACIA
  stz UART_STATUS_REG   ; also zero-out our status register
  stz STDIN_IDX         ; zero buffer index
  stz STDOUT_IDX        ; zero buffer index
  stz PROC_REG          ; initialised process register
  lda #ACIA_8N1_9600    ; set control register config - set speed & 8N1
  sta ACIA_CTRL_REG
  lda #ACIA_CMD_CFG     ; set command register config
  sta ACIA_CMD_REG
  rts
  
.acia_wait_send_clr
  pha                          ; push A to stack to save it
.acia_wait_send_loop        
  lda ACIA_STAT_REG            ; get contents of status register
  and #ACIA_TX_RDY_BIT         ; AND with ready bit
  beq acia_wait_send_loop      ; if it's zero, we're not ready yet
  pla                          ; otherwise, recover A from stack
  rts

.acia_wait_byte_recvd          ; not using this yet. Ever?
  lda ACIA_STAT_REG            ; Possibly if I implement flow control
  and #ACIA_RX_RDY_BIT
  beq acia_wait_byte_recvd
  rts

.stdout_prt_sendbuf            ; sends contents of send buffer and clears it
  ldx #0                       ; offset index
 .stdout_sendbuf_next_char
  lda STDOUT_BUF,X             ; load next char
  beq stdout_sendbuf_end       ; if char is 0, we've finished
  jsr acia_wait_send_clr       ; wait until ACIA is ready for another byte
  sta ACIA_DATA_REG            ; write to Data Reg. This sends the byte
  inx                          ; increment offset index
  cpx STDOUT_IDX               ; check if we're at the buffer index
  beq stdout_sendbuf_end       ; if so, end it here
  cpx #STDOUT_BUF_LEN          ; check against max size, to prevent overrun
  beq stdout_sendbuf_end       ; if so, end it here
  jmp stdout_sendbuf_next_char ; otherwise do the next char
.stdout_sendbuf_end
  stz STDOUT_IDX               ; re-zero the index
  rts

;.serial_send_hexval           ; assumes byte value is in A
;  pha : phx : phy             ; preserve registers
;  jsr byte_to_hex_str
;  lda #<TMP_BUF               ; Setting MSG_VEC to be the address of TMP_BUF
;  sta MSG_VEC                 ; but message is actually in STR_BUF
;  lda #>TMP_BUF               ; so is this right? I Think we should be using 
;  jsr stdout_println          ; STR_BUF instead of TMP_BUF
;  ply : plx : pla ; restore registers
;  rts

.stdout_prtlineend
  lda #CHR_LINEEND
  PRT_CHAR
  rts

.stdout_println
  pha : phy
  ldy #0                       ; set message offset to 0
.stdout_println_chr
  lda (MSG_VEC),Y              ; load next char
  beq stdout_println_end       ; if char is 0, we've finished
  jsr acia_wait_send_clr       ; wait for serial port to be ready
  sta ACIA_DATA_REG            ; write to data register. This sends the byte
  iny                          ; increment index
  jmp stdout_println_chr       ; go back for next character
.stdout_println_end
  ply : pla
  rts

.stdout_prterr                 ; mainly for debugging
  pha
  lda FUNC_ERR
  jsr byte_to_hex_str
  jsr stdout_prt_strbuf
  pla
  rts

.stdout_prt_strbuf
  pha
  PRT_MSG STR_BUF, stdout_println
  pla
  rts

.stdout_prtprompt               ; print the standard prompt
  PRT_MSG prompt_msg, stdout_println
  rts
