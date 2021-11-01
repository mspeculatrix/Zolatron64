; ---------TEXT SUBROUTINES-----------------------------------------------------

.byte_to_hex_str              ; convert 1-byte value to 2-char hex string
  ; assumes that number to be converted is in A
  tax                         ; keep a copy of A in X for later
  ldy #4                      ; we're going to shift right 4 times
.hexstr_shift_rt     
  lsr A                       ; logical shift right
  dey
  cpy #0                      ; is our counter at 0?
  bne hexstr_shift_rt
  ; at this point A contains upper nibble of value
  tay                         ; put in Y to act as offset
  lda hex_chr_tbl,Y           ; load A with appropriate char from lookup table
  sta TEXT_BUF                ; and stash that in the text buffer
  txa                         ; recover original value of A
  and #%00001111              ; mask to get lower nibble value
  tay                         ; again, put in Y to act as offset
  lda hex_chr_tbl,Y           ; load A with appropriate char from lookup table
  sta TEXT_BUF+1              ; and stash that in the next byte of the buffer
  lda #CHR_NUL                ; and end with a null byte
  sta TEXT_BUF+2
  rts
  