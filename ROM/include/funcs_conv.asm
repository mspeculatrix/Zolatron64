\ funcs_conv.asm

\ FUNCTIONS: Conversions -------------------------------------------------------
\

\ ------------------------------------------------------------------------------
\ ---  BYTE_TO_BIN
\ ---  Implements: OSB2BIN
\ ------------------------------------------------------------------------------
\ Convert 1-byte integer value to binary string representation.
\ ON ENTRY: Byte to be converted must be in A.
\ ON EXIT : Nul-terminated string STR_BUF. Byte 8 is null terminator.
\ A - O
\ X - P
\ Y - P
.byte_to_bin
  phx : phy
  sta TMP_VAL                   ; Preserve initial value
  ldx #0                        ; Index for STR_BUF
  lda #128
  sta TEST_VAL                  ; Bit mask for testing bits
.byte_to_bin_loop
  lda TMP_VAL
  and TEST_VAL                  ; AND supplied value with bit mask
  beq byte_to_bin_set_zero
  lda #'1'                      ; Not a 0 so must be ... umm ...
  jmp byte_to_bin_next
.byte_to_bin_set_zero
  lda #'0'
.byte_to_bin_next
  sta STR_BUF,X
  lsr TEST_VAL                  ; Shift bit mask
  inx
  cpx #8
  bne byte_to_bin_loop
  stz STR_BUF,X
  ply : plx
  rts

\ ------------------------------------------------------------------------------
\ ---  BYTE_TO_HEX_STR
\ ---  Implements: OSB2HEX
\ ------------------------------------------------------------------------------
\ Convert 1-byte value to 2-char hex string representation.
\ ON ENTRY: Byte to be converted must be in A.
\ ON EXIT : String in three bytes starting at STR_BUF. Third byte is a null
\           terminator.
\ A - O
\ X - P
\ Y - P
.byte_to_hex_str
  phx : phy
  tax                         ; Keep a copy of A in X for later
  lsr A                       ; Logical shift right 4 bits
  lsr A
  lsr A
  lsr A                       ; A now contains upper nibble of value
  tay                         ; Put in Y to act as offset
  lda hex_chr_tbl,Y           ; Load A with appropriate char from lookup table
  sta STR_BUF                 ; and stash that in the text buffer
  txa                         ; Recover original value of A
  and #%00001111              ; Mask to get lower nibble value
  tay                         ; Again, put in Y to act as offset
  lda hex_chr_tbl,Y           ; Load A with appropriate char from lookup table
  sta STR_BUF+1               ; and stash that in the next byte of the buffer
  stz STR_BUF+2               ; End with a null byte
  txa                         ; Restore A to original value.
  ply : plx
  rts

\ ------------------------------------------------------------------------------
\ ---  BYTE_TO_INT_STR  ; Convert 1-byte value to decimal string representation
\ ---  Implements: OSB2ISTR
\ ------------------------------------------------------------------------------
\ ON ENTRY: A contains the number to be converted
\ ON EXIT : STR_BUF contains decimal string representation, nul-terminated.
\ A - O
\ X - P
\ Y - P
.byte_to_int_str
  pha : phx : phy
  stz TMP_IDX             ; Keep track of digits in buffer
  stz STR_BUF             ; Set nul terminator at start of buffer
.byte_to_int_str_next_digit
  ldx #10                 ; Divisor for MOD function
  jsr uint8_div           ; FUNC_RESULT contains remainder, X contains quotient
  txa                     ; Transfer quotient to A as dividend for next round
  pha                     ; Protect it for now
  ldy TMP_IDX             ; Use the index as an offset
.byte_to_int_str_add_loop
  lda STR_BUF,Y           ; Load whatever is currently at the index position
  iny
  sta STR_BUF,Y           ; Move it to the next position
  dey
  beq byte_to_int_str_add_loop_done   ; If index=0, finished with moving digits
  dey                     ; Otherwise, decrement the offset and go around again
  jmp byte_to_int_str_add_loop
.byte_to_int_str_add_loop_done
  inc TMP_IDX             ; Increment our digit index
  lda FUNC_RESULT         ; Get the remainder from the MOD operation
  clc
  adc #$30                ; Add $30 to get the ASCII code
  sta STR_BUF             ; And store it in the first byte of the buffer
  pla                     ; Bring back that quotient, as dividend for next loop
  cpx #0                  ; If it's 0, we're done...
  beq byte_to_int_str_done
  jmp byte_to_int_str_next_digit
.byte_to_int_str_done
  ply : plx : pla
  rts

\ ------------------------------------------------------------------------------
\ ---  HEX_STR_TO_BYTE
\ ---  Implements: OSHEX2B
\ ------------------------------------------------------------------------------
\ Converts 2-char hex string representation to a byte value.
\ ON ENTRY: ASCII codes for hex value must be in BYTE_CONV_H and BYTE_CONV_L.
\ ON EXIT : - Byte value is in FUNC_RESULT.
\           - Error in FUNC_ERR
\ A - P
\ X - P
\ Y - n/a
.hex_str_to_byte              ; assumes text is in BYTE_CONV_H and BYTE_CONV_L
  pha : phx
  stz FUNC_ERR                ; Zero out function error
  stz FUNC_RESULT             ; Zero-out return result
  lda BYTE_CONV_H             ; Load the high nibble character
  jsr asc_hex_to_dec          ; Convert to number - result is in A
  ldx FUNC_ERR
  bne hex_str_to_byte_err
  asl A                       ; Shift to high nibble
  asl A
  asl A
  asl A
  sta FUNC_RESULT             ; And store
  lda BYTE_CONV_L             ; Get the low nibble character
  jsr asc_hex_to_dec          ; Convert to number - result is in A
  ldx FUNC_ERR
  bne hex_str_to_byte_err
  ora FUNC_RESULT             ; OR with previous result
  sta FUNC_RESULT             ; and store final result
  jmp hex_str_to_byte_end
.hex_str_to_byte_err
  stz FUNC_RESULT
.hex_str_to_byte_end
  plx : pla
  rts

\ ------------------------------------------------------------------------------
\ ---  ASC_HEX_TO_DEC
\ ---  Implements: OSHEX2DEC
\ ------------------------------------------------------------------------------
\ Converts 1-byte char representing an ASCII value for a hex character -
\ ie, '0' to 'F' and returns the corresponding one-byte numerical value -
\ ie, 0 to 15.
\ ON ENTRY: A contains ASCII character value
\ ON EXIT : - A contains corresponding numeric value
\           - Error in FUNC_ERR
\ A - n/a
\ X - P
\ Y - n/a
.asc_hex_to_dec
  phx
  stz FUNC_ERR                ; Zero-out error
  sec
  sbc #$30                    ; Subtract $30 - this is good for 0-9
  cmp #10                     ; Ss value more than 10?
  bcc asc_hex_to_dec_end      ; If not, we're okay
  sbc #$07                    ; Otherwise subtract further for A-F
  cmp #16                     ; Result should be less than 16
  bcc asc_hex_to_dec_end
.asc_hex_to_dec_err
  ldx #HEX_TO_BIN_ERR_CODE    ; Set error code
  stx FUNC_ERR
.asc_hex_to_dec_end
  plx
  rts

\ ------------------------------------------------------------------------------
\ ---  UINT16_TO_HEX_STR
\ ---  Implement: OSU16HEX
\ ------------------------------------------------------------------------------
\ Takes the 16-bit value in TMP_ADDR_A/+1 and converts it to a four-char
\ hex string.
\ ON ENTRY: 16-bit value expected in TMP_ADDR_A/+1
\ ON EXIT : Hex string in STR_BUF
\ A - P
\ X - n/a
\ Y - n/a
.uint16_to_hex_str
  pha
  lda TMP_ADDR_A_L
  jsr byte_to_hex_str
  lda STR_BUF                 ; STR_BUF contains the two chars for the low byte,
  sta TMP_WORD_L              ; but at locations 0 & 1.
  lda STR_BUF + 1             ; Put these in temporary locations
  sta TMP_WORD_H
  lda TMP_ADDR_A_H              ; Now process the high byte
  jsr byte_to_hex_str         ; This is now in STR_BUF
  lda TMP_WORD_L              ; Move our previous results into the appropriate
  sta STR_BUF + 2             ; locations in STR_BUF
  lda TMP_WORD_H
  sta STR_BUF + 3
  stz STR_BUF + 4             ; Add a null terminator
  pla
  rts

\ ------------------------------------------------------------------------------
\ ---  UINT16_INTSTR
\ ---  Implements: OSU16ISTR
\ ------------------------------------------------------------------------------
\ Takes the 16-bit value in MATH_TMP_A/+1 and converts it to a string
\ representation of the decimal integer value.
\ ON ENTRY: - 16-bit value expected in MATH_TMP_A/+1
\ ON EXIT : - String in STR_BUF
\ A - P
\ X - P
\ Y - P
.uint16_intstr
  pha : phx : phy
  ; stz TMP_IDX             ; Keep track of digits in buffer
  stz STR_BUF               ; Set nul terminator at start of buffer
  lda #10
  sta MATH_TMP_B
  stz MATH_TMP_B+1
.uint16_intstr_loop
  jsr uint16_div            ; Remainder in FUNC_RES_L; quotient in MATH_TMP_A/+1
.uint16_intstr_next
  lda FUNC_RES_L
  clc
  adc #$30                  ; Add 30 to get ASCII
;  jsr uint16_intstr_addchar
  pha                       ; Save it on stack for now
  ldy #0
.uint16_intstr_buf_loop
  lda STR_BUF,Y             ; Get next char in current string
  tax                       ; Temporarily save it
  pla                       ; Bring back our new char
  sta STR_BUF,Y             ; to replace what was there before
  iny
  txa                       ; Bring back previous char
  pha                       ; An push onto stack for next iteration
  bne uint16_intstr_buf_loop
  pla                       ; This will be null char
  sta STR_BUF,Y
  lda MATH_TMP_A            ; Check quotient. If 0, we're done
  ora MATH_TMP_A+1
  bne uint16_intstr_loop
.uint16_intstr_done
  ply : plx : pla
  rts
