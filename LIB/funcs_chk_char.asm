\ Functions to be used in user programs or OS

\ ------------------------------------------------------------------------------
\ --- ISALPHA
\ ------------------------------------------------------------------------------
\ Check to see if a byte represents a valid ASCII character in the range
\ 'A'-'Z' or 'a'-'z'
\ ON ENTRY: A holds character value
\ ON EXIT : - Carry bit clear if valid char
\           - Carry bit set if not valid
\           - A is preserved
.isAlpha
  pha
  and #$DF      ; Converts lowercase to upper. Uppercase not affected
  jsr isUpper
  rts

\ ------------------------------------------------------------------------------
\ --- ISNUMERAL
\ ------------------------------------------------------------------------------
\ Check to see if a byte represents a valid ASCII character in the range
\ '0'-'9'
\ ON ENTRY: A holds character value
\ ON EXIT : - Carry bit clear if valid char
\           - Carry bit set if not valid
\           - A is preserved
.isNumeral
  pha
  sec
  sbc #'0'      ; This puts valid values in range 0-9
  cmp #10       ; Will set carry if value 10 or more
  pla
  rts

\ ------------------------------------------------------------------------------
\ ---  ISUPPER
\ ------------------------------------------------------------------------------
\ Check to see if a byte represents a valid ASCII character in the range
\ 'A'-'Z'
\ ON ENTRY: A holds character value
\ ON EXIT : - Carry bit clear if valid char
\           - Carry bit set if not valid
\           - A is preserved
.isUpper  
  pha
  sec
  sbc #'A'      ; This puts valid values in range 0-25
  cmp #26       ; Will set carry if value 26 or more
  pla
  rts
