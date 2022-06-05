; zumpus_funcs.asm

\ ------------------------------------------------------------------------------
\ ---  get_decimal_input
\ ---  Read a decimal number from STDIN_BUF
\ ------------------------------------------------------------------------------
\ ON EXIT : - 16-bit unsigned integer in MATH_TMP16, MATH_TMP16+1
\           - Error code in FUNC_ERR
\ *** REPLACE WITH OSRDINT ***
\ ------------------------------------------------------------------------------
.get_decimal_input
  ldx #0                      ; Offset for STDIN_BUF
  stz MATH_TMP16              ; To hold our result
  stz MATH_TMP16 + 1
  stz FUNC_ERR
.get_decimal_char
  txa                         ; Transfer a copy of the X offset to Y
  tay                         ; "
  iny                         ; Make Y an index to the char _after_ this one
  lda STDIN_BUF,X
  beq get_decimal_done        ; If it's a 0 terminator, we're done
  cmp #' '
  beq get_decimal_char        ; Ignore spaces
  cmp #'0'
  bcc get_decimal_error       ; Less than '0'
  cmp #$3A                    ; ASCII for ':', char above '9'
  bcs get_decimal_error       ; More than '9'
  sec
  sbc #$30                    ; Turn ASCII value into integer digit
  clc                         ; Now got the value of the digit in A
  adc MATH_TMP16              ; Add this value to our result
  sta MATH_TMP16
  bcs get_decimal_carry       ; Did we carry?
  jmp get_decimal_mult
.get_decimal_carry
  inc MATH_TMP16+1
.get_decimal_mult             ; Check if we need to multiply value by 10
  lda STDIN_BUF,Y             ; Look ahead to next char
  beq get_decimal_done        ; If a zero, the current one is the last digit
  jsr uint16_times10          ; Otherwise, multiply the current sum by 10
.get_decimal_next             ; Get the next digit
  inx
  jmp get_decimal_char
.get_decimal_error
  lda #NOT_A_NUMBER
  sta FUNC_ERR
.get_decimal_done
  rts



.init_check_unique
  phx
  stz FUNC_RESULT
  cpy #0
  beq init_check_random_done
  tya                           ; Location offset is in Y - use a copy in X
  tax
.init_check_random_next
  dex                           ; Decrement to compare with previous location
  lda RANDOM_LOCS,Y
  cmp RANDOM_LOCS,X
  bne init_check_random_chk     ; Go check if we're at the end of the locations
  inc FUNC_RESULT
  jmp init_check_random_done
.init_check_random_chk
  cpx #0
  bne init_check_random_next
.init_check_random_done
  plx
  rts

.list_locs                ; FOR DEBUGGING ONLY
  ldx #0
.list_locs_loop
  lda RANDOM_LOCS,X
  jsr OSB2HEX
  jsr OSWRSBUF
  lda #' '
  jsr OSWRCH
  inx
  cpx #NUM_LOCS
  beq list_locs_done
  jmp list_locs_loop
.list_locs_done
  lda #CHR_LINEEND
  jsr OSWRCH
  rts

\ Assumes the current room number is in A.
\ Assumes the three bytes to which you want to store the room numbers start at
\ the address pointed to by TMP_ADDR_A.
.find_adjacent_rooms
  clc
  asl A                                 ; Need to multiply by 4
  asl A
  tax                                   ; Offset counter for lookup table
  ldy #0                                ; Offset counter for storing numbers
.find_adjacent_rooms_next
  lda connections,X
  sta (TMP_ADDR_A),Y
  iny
  inx
  cpy #3
  beq find_adjacent_rooms_done
  jmp find_adjacent_rooms_next
.find_adjacent_rooms_done
  rts

.set_player_connecting_rooms
  lda #<P_CONN_ROOMS
  sta TMP_ADDR_A
  lda #>P_CONN_ROOMS
  sta TMP_ADDR_A+1
  lda PLAYER_LOC
  jsr find_adjacent_rooms
  rts

.show_connecting_rooms
  LOAD_MSG connecting_rooms_msg
  jsr OSWRMSG
  ldx #0
.show_connecting_rooms_next
  lda P_CONN_ROOMS,X
  phx
  jsr print_room_num
  plx
  lda #' '
  jsr OSWRCH
  inx
  cpx #3
  beq show_connecting_rooms_done
  jmp show_connecting_rooms_next
.show_connecting_rooms_done
  NEWLINE
  rts

.current_room
  LOAD_MSG current_room_msg
  jsr OSWRMSG
  lda PLAYER_LOC
  jsr print_room_num
  NEWLINE
  rts

.staple_count
  lda STAPLE_COUNT
  pha
  beq staples_none
  LOAD_MSG staple_count_msg
  jsr OSWRMSG
  pla
  clc
  adc #$30                            ; To get ASCII char
  sta BARLED_DAT
  jsr OSWRCH
  LOAD_MSG staple_count_msg_end
  jsr OSWRMSG
  jmp staple_count_end
.staples_none
  LOAD_MSG staple_count_none_msg
  jsr OSWRMSG
.staple_count_end
  lda #' '
  jsr OSWRCH
  ldx STAPLE_COUNT
.staple_loop
  lda #91                             ; Open square bracket
  jsr OSWRCH
  dex
  bne staple_loop
  rts

.print_room_num ; location in A
  inc A
  jsr uint8_decstr
  jsr OSWRSBUF
  rts

.status_update
  jsr current_room
  jsr set_player_connecting_rooms
  jsr show_connecting_rooms
  jsr staple_count
  NEWLINE
  jsr warnings
  NEWLINE
  LOAD_MSG debug_heading   ; ---- THIS IS ALL DEBUGGING STUFF
  jsr OSWRMSG
  lda ZUMPUS_LOC
  jsr print_room_num
  NEWLINE
  LOAD_MSG bat1_msg
  jsr OSWRMSG
  lda BAT1_LOC
  jsr print_room_num
  NEWLINE
  LOAD_MSG bat2_msg
  jsr OSWRMSG
  lda BAT2_LOC
  jsr print_room_num
  NEWLINE
  LOAD_MSG pit1_msg
  jsr OSWRMSG
  lda PIT1_LOC
  jsr print_room_num
  NEWLINE
  LOAD_MSG pit2_msg
  jsr OSWRMSG
  lda PIT2_LOC
  jsr print_room_num
  NEWLINE
  rts

\ ------------------------------------------------------------------------------
\ ---  uint8_mod8
\ ---  MOD/DIV an 8-bit number by another 8-bit number
\ ------------------------------------------------------------------------------
\ ON ENTRY: - A must contain the dividend - the number to be modded
\			      - X must contain the divisor
\ ON EXIT : - FUNC_RESULT contains remainder
\           - X contains quotient (number of divisions. X=0 if num < divisor) 
.uint8_mod8
  stx TMP_VAL
  ldx #0
.uint8_mod8_loop
  sta FUNC_RESULT
  sec
  sbc TMP_VAL
  bcc uint8_mod8_result   ; We've gone too far
  inx
  jmp uint8_mod8_loop
.uint8_mod8_result
  rts

\ ------------------------------------------------------------------------------
\ ---  uint8_decstr
\ ---  Convert an 8-bit unsigned integer to a decimal string
\ ------------------------------------------------------------------------------
\ ON ENTRY: A contains the number to be converted
\ ON EXIT : STR_BUF contains decimal string representation, nul-terminated.
.uint8_decstr
  stz TMP_IDX             ; Keep track of digits in buffer
  stz STR_BUF             ; Set nul terminator at start of buffer
.uint8_decstr_next_digit
  ldx #10                 ; Divisor for MOD function
  jsr uint8_mod8          ; FUNC_RESULT contains remainder, X contains quotient
  txa                     ; Transfer quotient to A as dividend for next round
  pha                     ; Protect it for now
  ldy TMP_IDX             ; Use the index as an offset
.uint8_decstr_add_loop
  lda STR_BUF,Y           ; Load whatever is currently at the index position
  iny
  sta STR_BUF,Y           ; Move it to the next position
  dey
  cpy #0                  ; If the index is 0, we've finished with moving digits
  beq uint8_decstr_add_loop_done
  dey                     ; Otherwise, decrement the offset and go around again
  jmp uint8_decstr_add_loop
.uint8_decstr_add_loop_done
  inc TMP_IDX             ; Increment our digit index
  lda FUNC_RESULT         ; Get the remainder from the MOD operation
  clc
  adc #$30                ; Add $30 to get the ASCII code
  sta STR_BUF             ; And store it in the first byte of the buffer
  pla                     ; Bring back that quotient, as dividend for next loop
  cpx #0                  ; If it's 0, we're done...
  beq uint8_decstr_done
  jmp uint8_decstr_next_digit
.uint8_decstr_done
  rts

\ ------------------------------------------------------------------------------
\ ---  uint16_decstr
\ ---  Convert a 16-bit unsigned integer to a decimal string
\ ------------------------------------------------------------------------------
\ ON ENTRY: 16-bit number in MATH_TMP16, MATH_TMP16+1
\ ON EXIT : STR_BUF contains decimal string representation, nul-terminated.
.uint16_decstr
  ; to come
  rts

\ ------------------------------------------------------------------------------
\ ---  roll_dice
\ ---  Get a random number in range 0..59 or random true/false value
\ ------------------------------------------------------------------------------
\ A 'threshold' value (in Y) will be used to determine a true (1) or false (0) 
\ return value. The rule is:
\    Counter < threshold - FALSE
\    Counter >= threshold - TRUE
\ If you don't care about a true/false value, then don't worry about what's
\ in Y.
\ ON ENTRY: - X must contain the divisor for MODding, or 0 if no MOD needed.
\           - Y should contain the threshold value - if a true/false value
\             is required.
\ ON EXIT : - A will contain the actual value of the counter MODded by X.
\           - FUNC_RESULT will contain the true/false value (0 or 1)
\ ------------------------------------------------------------------------------
.roll_dice
  stz FUNC_RESULT         ; Set to 0 (false) by default
  lda VIAC_T1CL           ; Put Counter value in X
  cmp #$FF                ; Sometimes this pops up - don't know why
  bne roll_dice_mod
  lda #0
.roll_dice_mod
  cpx #0                  ; Do we want to mod?
  beq roll_dice_store     ; No, if X=0
  jsr uint8_mod8
  lda FUNC_RESULT
.roll_dice_store
  sty TEST_VAL            ; Put threshold value in TEST_VAL
  cmp TEST_VAL            ; Compare to our random number in A
  bcc roll_dice_end       ; random num < threshold, so default value is fine
  ldy #1                  ; Otherwise, return a true value
  sty FUNC_RESULT
.roll_dice_end
  rts

.warnings
  ldy #0
  ldx #0
  lda FLAGS
  and #%11111100            ; Clear the PIT/BAT warning flags
  sta FLAGS
.warning_loop
  lda P_CONN_ROOMS,X
  cmp ZUMPUS_LOC
  beq warning_zumpus
  cmp BAT1_LOC
  beq warning_bat
  cmp BAT2_LOC
  beq warning_bat
  cmp PIT1_LOC
  beq warning_pit
  cmp PIT2_LOC
  beq warning_pit
  jmp warning_next
.warning_zumpus
  LOAD_MSG warning_zumpus_msg
  jsr OSWRMSG
  NEWLINE
  jmp warning_next
.warning_bat
  lda FLAGS
  and #BAT_WARNING_ISSUED
  bne warning_next            ; Means the flag was already set
  lda FLAGS
  ora #BAT_WARNING_ISSUED
  sta FLAGS
  LOAD_MSG warning_bat_msg
  jsr OSWRMSG
  NEWLINE
  jmp warning_next
.warning_pit
  lda FLAGS
  and #PIT_WARNING_ISSUED
  bne warning_next            ; Means the flag was already set
  lda FLAGS
  ora #PIT_WARNING_ISSUED
  sta FLAGS
  LOAD_MSG warning_pit_msg
  jsr OSWRMSG
  NEWLINE
.warning_next
  inx
  cpx #3
  beq warnings_done
  jmp warning_loop
.warnings_done
  rts
  