; FUNCTIONS: SERIAL -- funcs_serial.asm ----------------------------------------
; v07 - 10 Nov 2021
;

.acia_wait_send_clr
  pha                     ; push A to stack to save it
.acia_wait_send_loop        
  lda ACIA_STAT_REG       ; get contents of status register
  and #ACIA_TX_RDY_BIT    ; AND with ready bit
  beq acia_wait_send_loop ; if it's zero, we're not ready yet
  pla                     ; otherwise, recover A from stack
  rts

.acia_wait_byte_recvd       ; not using this yet. Ever?
  lda ACIA_STAT_REG         ; Possibly if I implement flow control
  and #ACIA_RX_RDY_BIT
  beq acia_wait_byte_recvd
  rts

.serial_print_rx_buf
  lda #LCD_CLS              ; clear display, reset display memory
  jsr lcd_cmd
  jsr serial_send_prompt    ; send our standard prompt
  lda UART_STATUS_REG       ; get our info register
  and #UART_CLEAR_RX_FLAGS  ; zero all the RX flags
  sta UART_STATUS_REG       ; and re-save the register
  ldx #0                    ; our buffer offset index
.get_rx_char
  lda UART_RX_BUF,X         ; get the next byte in the buffer
  beq end_print_rx          ; if it's a zero terminator, we're done
  jsr lcd_prt_chr           ; otherwise, print char to LCD
  inx                       ; increment index
  cpx UART_RX_IDX           ; have we reached the last char?
  beq end_print_rx          ; if so, we're done
  cpx #UART_RX_BUF_MAX      ; or are we at the end of the buffer?
  bne get_rx_char           ; if not, get another char
.end_print_rx
  stz UART_RX_IDX           ; reset buffer index
  stz UART_RX_BUF           ; and reset first byte in buffer to 0
  rts

.serial_send_buffer         ; sends contents of send buffer and clears it
  ldx #0                    ; offset index
 .serial_send_next_char
  lda UART_TX_BUF,X         ; load next char
  beq serial_send_buf_end   ; if char is 0, we've finished
  jsr acia_wait_send_clr    ; wait until ACIA is ready for another byte
  sta ACIA_DATA_REG         ; write to Data Reg. This sends the byte
  inx                       ; increment offset index
  cpx UART_TX_IDX           ; check if we're at the buffer index
  beq serial_send_buf_end   ; if so, end it here
  cpx #UART_TX_BUF_LEN      ; check against max buffer size, to prevent overrun
  beq serial_send_buf_end   ; if so, end it here
  jmp serial_send_next_char ; otherwise do the next char
.serial_send_buf_end
  stz UART_TX_IDX           ; re-zero the index
  rts

.serial_send_char             ; send a single char - assumes char is in A
  jsr acia_wait_send_clr
  sta ACIA_DATA_REG           ; write to data register. This sends the byte
  rts

.serial_send_hexval           ; assumes byte value is in A
  pha : phx : phy ; preserve registers
  jsr byte_to_hex_str
  lda #<TMP_BUF
  sta MSG_VEC
  lda #>TMP_BUF
  sta MSG_VEC+1
  jsr serial_send_msg
  ply : plx : pla ; restore registers
  rts

.serial_send_lineend
  lda #CHR_LINEEND
  jsr acia_wait_send_clr      ; wait for serial port to be ready
  sta ACIA_DATA_REG           ; write to data register. This sends the byte
  rts

.serial_send_msg
  pha : phy
  ldy #0                      ; set message offset to 0
.serial_send_msg_chr
  lda (MSG_VEC),Y             ; load next char
  beq serial_send_msg_end     ; if char is 0, we've finished
  jsr acia_wait_send_clr      ; wait for serial port to be ready
  sta ACIA_DATA_REG           ; write to data register. This sends the byte
  iny                         ; increment index
  jmp serial_send_msg_chr     ; go back for next character
.serial_send_msg_end
  ply : pla
  rts

.serial_send_prompt
  lda #<prompt_msg            ; get LSB of message
  sta MSG_VEC                 ; save to message vector
  lda #>prompt_msg            ; get MSB of message
  sta MSG_VEC+1               ; save to message vector + 1
  jsr serial_send_msg
  rts
