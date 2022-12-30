.parse_bet_code
  ldx #0                  ; Index for input string
  ldy #0                  ; Offset for bet

.pbc_loop
  lda STDIN_BUF,X         ; Get next char from buffer
.pbc_loop_next
  sta TMP_VAL
  lda bets_first_char,Y
  beq pbc_loop_fail       ; We hit the zero end marker
  cmp TMP_VAL
  beq pbc_test_next
  iny

.pbc_test_next            ; test the second char

.pbc_loop_fail


  jsr is_digit
  bne pbc_get_code        ; Not a digit, so check other things
  lda STDIN_BUF
  cmp #'0'                ; Is first char a 0?
  bne pbc_get_number      ; If not, go read the number
  lda STDIN_BUF+1         ; Otherwise, check second char
  cmp #'0'                ; Is the second char also a '0'?
  bne pbc_get_number      ; If not, just go read the number
  lda #37                 ; Otherwise load the code for '00'

.pbc_get_number

.pbc_get_code


.pbc_done
  rts


\ Is the value in A in the range "0"-"9"?
\ Returns 1 in A if value is a value digit, 0 otherwise
.is_digit
  cmp #'0'
  bcc is_digit_no			; Less than "0"
  cmp #':'
  bcs is_digit_no			; More than "9"
  lda #1
  jmp is_digit_done
.is_digit_no
  lda #0
.is_digit_done
  rts
