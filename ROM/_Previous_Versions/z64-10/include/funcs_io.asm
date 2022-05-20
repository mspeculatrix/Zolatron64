; funcs_io.asm

; ------------------------------------------------------------------------------
; ---  READ HEX ADDRESS                                                      ---
; ------------------------------------------------------------------------------
.read_hex_addr
; This function reads four characters from the serial input and converts them to
; a 16-bit address, stored LSB first, in FUNC_RES_L/FUNC_RES_H.
; This function assumes that X contains an offset pointer to the part of
; UART_RX_BUF from which we want to read next.
; USES: FUNC_RES, FUNC_RES_L, FUNC_RES_H
  pha : phy
  ldy #1                    ; offset for where we're storing each byte from buf
.read_hex_addr_next_byte
  jsr read_hex_byte         ; byte value result is in FUNC_RES
  lda FUNC_RESULT           ; load the result from the previous conversion
  sta FUNC_RES_L,Y
  cpy #0
  beq read_hex_addr_end
  dey
  jmp read_hex_addr_next_byte
.read_hex_addr_end
  ply : pla
  rts

; ------------------------------------------------------------------------------
; ---  READ HEX BYTE                                                         ---
; ------------------------------------------------------------------------------
.read_hex_byte
  ; Reads a pair of ASCII hex chars from the serial buffer and converts to
  ; a byte value. Returns result in FUNC_RESULT.
  ; This function assumes that X contains an offset pointer to the part of
  ; UART_RX_BUF from which we want to read next.
  pha : phy
  ldy #1                    ; offset for where we're storing each byte from buf
.read_hexbyte_next_char
  lda UART_RX_BUF,X         ; get next byte from serial buffer
  inx                       ; increment for next time
  cmp #0                    ; is the buffer char a null? Shouldn't be
  beq read_hexbyte_fail   ; - that's an error
  cmp #$20                  ; if it's a space, ignore it & get next byte
  beq read_hexbyte_next_char
  sta BYTE_CONV_L,Y         ; store in BYTE_CONV buffer, high byte first
  cpy #0                    
  beq read_hexbyte_conv     ; if 0, we've now got the second of the 2 bytes
  dey                       ; otherwise go get low byte
  jmp read_hexbyte_next_char
.read_hexbyte_conv
  ; we've got our pair of bytes in BYTE_CONV_L and BYTE_CONV_L+1
  jsr hex_str_to_byte       ; convert them - result is in FUNC_RESULT
  lda #$00                  ; check to see if there was an error
  cmp FUNC_ERR
  bne read_hexbyte_fail
  jmp read_hexbyte_end
.read_hexbyte_fail
  lda #READ_HEXBYTE_ERR
  sta FUNC_ERR  
.read_hexbyte_end
  ply : pla
  rts