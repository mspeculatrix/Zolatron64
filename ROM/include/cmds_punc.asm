\ ------------------------------------------------------------------------------
\ --- CMD: !  :  ENTER BYTE(S) IN MEMORY
\ ------------------------------------------------------------------------------
\ Usage: ! <addr> <hexbyte> [<hexbyte>, <hexbyte>, ...]
\ Allows you to enter up to 16 bytes starting at the memory address given.
.cmdprcBANG
  jsr read_hex_addr         ; Puts address bytes in FUNC_RES_L, FUNC_RES_H
  lda FUNC_ERR
  bne cmdprcBANG_fail

  ldy #0
.cmdprcBANG_loop
  jsr read_hex_byte         ; Get byte value - puts result in FUNC_RESULT
  lda FUNC_ERR
  bne cmdprcBANG_fail

  lda FUNC_RESULT           ; Retrieve the byte
  sta (FUNC_RES_L)          ; and store - this has the address we were given

  ldx STDIN_IDX             ; Check what's next in the buffer
  lda STDIN_BUF,X           ; Check there's nothing left in the RX buffer
  beq cmdprcBANG_success    ; If it's a nul, we're done
  iny
  cpy #16
  beq cmdprcBANG_success       ; If w've got 16 bytes, we're done
  inc FUNC_RES_L            ; Increment low byte of address
  bne cmdprcBANG_loop       ; If it didn't roll over, good to go again
  inc FUNC_RES_H
  jmp cmdprcBANG_loop

.cmdprcBANG_success
  stz STDIN_IDX
  stz STDIN_BUF
  LOAD_MSG okay_masg
  jsr OSWRMSG
  jmp cmdprc_success
.cmdprcBANG_fail
  stz STDIN_IDX
  stz STDIN_BUF
  jmp cmdprc_fail


\ ------------------------------------------------------------------------------
\ --- CMD: ?  :  EXAMINE BYTE(S) IN MEMORY
\ ------------------------------------------------------------------------------
\ Usage: ? <addr>
\ Show the value of a byte at a specific address.
\ Expects a two-byte hex address as input.
\ Pressing <return> increments the address and shows the next byte.
\ Entering <Q> <return> stops the routine.
.cmdprcQUERY
  jsr read_hex_addr         ; Get address - puts bytes in FUNC_RES_L, FUNC_RES_H
  lda FUNC_ERR
  bne cmdprcQUERY_fail
;  ldx STDIN_IDX
;  lda STDIN_BUF,X            ; Check there's nothing left in the RX buffer
;  bne cmdprcQUERY_fail       ; Should be null. Anything else is a mistake
.cmdprcQUERY_loop
  lda (FUNC_RES_L)
  jsr byte_to_hex_str       ; Resulting string is in STR_BUF
  jsr OSWRSBUF
  lda #' '
  jsr OSWRCH
.cmdprcQUERY_getkey
  jsr getkey
  lda FUNC_RESULT
  cmp #'Q'
  beq cmdprcQUERY_done
  inc FUNC_RES_L						          ; Increment address
  bne cmdprcQUERY_loop                ; Isn't zero so didn't roll over
  inc FUNC_RES_H                      ; Did roll over, so increment high byte
  beq cmdprcQUERY_done	              ; Rolled over, so we're at top of memory
  jmp cmdprcQUERY_loop
.cmdprcQUERY_done
  jmp cmdprc_success
.cmdprcQUERY_fail
  lda #SYNTAX_ERR_CODE
  sta FUNC_ERR
  jmp cmdprc_fail
