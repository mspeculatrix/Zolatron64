; FUNCTIONS: Conversions -- funcs_conv.asm -------------------------------------
;

; Convert 1-byte value to 2-char hex string representation. Stores result in
; three bytes starting at STR_BUF. Third byte is a null terminator.
.byte_to_hex_str              ; assumes that byte to be converted is in A
  pha : phx : phy
  tax                         ; keep a copy of A in X for later
  lsr A                       ; logical shift right 4 bits
  lsr A
  lsr A
  lsr A                       ; A now contains upper nibble of value
  tay                         ; put in Y to act as offset
  lda hex_chr_tbl,Y           ; load A with appropriate char from lookup table
  sta STR_BUF                 ; and stash that in the text buffer
  txa                         ; recover original value of A
  and #%00001111              ; mask to get lower nibble value
  tay                         ; again, put in Y to act as offset
  lda hex_chr_tbl,Y           ; load A with appropriate char from lookup table
  sta STR_BUF+1               ; and stash that in the next byte of the buffer
  stz STR_BUF+2               ; end with a null byte
  ply : plx : pla
  rts
  
.hex_str_to_byte              ; assumes text is in BYTE_CONV_H and BYTE_CONV_L
  pha : phx
  stz FUNC_ERR                ; zero out function error
  stz FUNC_RESULT             ; zero-out return result
  lda BYTE_CONV_H             ; load the high nibble character
  jsr asc_hex_to_bin          ; convert to number - result is in A
  ldx #$0
  cpx FUNC_ERR
  bne hex_str_to_byte_err
  asl A                       ; shift to high nibble
  asl A 
  asl A 
  asl A
  sta FUNC_RESULT             ; and store
  lda BYTE_CONV_L             ; get the low nibble character
  jsr asc_hex_to_bin          ; convert to number - result is in A
  ldx #$00
  cpx FUNC_ERR
  bne hex_str_to_byte_err
  ora FUNC_RESULT             ; OR with previous result
  sta FUNC_RESULT             ; and store final result
  jmp hex_str_to_byte_end
.hex_str_to_byte_err
  stz FUNC_RESULT
.hex_str_to_byte_end
  plx : pla
  rts

.asc_hex_to_bin               ; assumes ASCII char val is in A
  phx
  stz FUNC_ERR                ; zero-out error
  sec
  sbc #$30                    ; subtract $30 - this is good for 0-9
  cmp #10                     ; is value more than 10?
  bcc asc_hex_to_bin_end      ; if not, we're okay
;  sec
  sbc #$07                    ; otherwise subtract further for A-F
  cmp #16                     ; result should be less than 16
  bcc asc_hex_to_bin_end
.asc_hex_to_bin_err
  ldx #HEX_TO_BIN_ERR_CODE    ; set error code
  stx FUNC_ERR
  ; jsr serial_prt_err        ; FOR DEBUGGING ONLY
.asc_hex_to_bin_end
  plx
  rts                         ; value is returned in A

.res_word_to_hex_str          ; takes the 16-bit value in FUNC_RES_L/H and
  pha                         ; converts to a four-byte hex string stored 
  lda FUNC_RES_L              ; in STR_BUF
  jsr byte_to_hex_str
  lda STR_BUF                 ; STR_BUF contains the two chars for the low byte, 
  sta TMP_WORD_L              ; but at locations 0 & 1.
  lda STR_BUF + 1             ; Put these in temporary locations
  sta TMP_WORD_H
  lda FUNC_RES_H              ; Now process the high byte
  jsr byte_to_hex_str         ; This is now in STR_BUF
  lda TMP_WORD_L              ; Move our previous results into the appropriate
  sta STR_BUF + 2             ; locations in STR_BUF
  lda TMP_WORD_H
  sta STR_BUF + 3
  stz STR_BUF + 4             ; Null terminator
  pla
  rts
