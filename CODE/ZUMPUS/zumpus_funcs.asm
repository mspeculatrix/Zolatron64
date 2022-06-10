; zumpus_funcs.asm

\ ------------------------------------------------------------------------------
\ ---  CHECK_CONNECTING_ROOMS
\ ------------------------------------------------------------------------------
\ Check whether the room number in ROOM_NUM is a valid connecting room.
\ Assumes the three bytes containing valid room numbers start at
\ the address pointed to by TMP_ADDR_A.
\ Returns a value in FUNC_RESULT: 0 = no match, 1 = match
.check_connecting_rooms
  ldy #0
  stz FUNC_RESULT
.check_connecting_rooms_loop
  lda (TMP_ADDR_A),Y
  cmp ROOM_NUM
  beq check_connecting_rooms_valid
  iny
  cpy #3
  beq check_connecting_rooms_end
  jmp check_connecting_rooms_loop
.check_connecting_rooms_valid
  inc FUNC_RESULT
.check_connecting_rooms_end
  rts

\ ------------------------------------------------------------------------------
\ ---  FIND_ADJACENT_ROOMS
\ ------------------------------------------------------------------------------
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

\ ------------------------------------------------------------------------------
\ ---  GET_INPUT_ROOM
\ ------------------------------------------------------------------------------
\ Get the room number entered by the player and check that it is a valid - ie,
\ a connecting - room.
\ ON EXIT : - Room number is in ROOM_NUM
\           - Error is in FUNC_ERR
.get_input_room
  ; The next thing in the input buf should be the number of the room
  stz FUNC_ERR
  jsr OSRDINT16                 ; Read the room number from STDIN_BUF
  lda FUNC_ERR                  ; Check for error
  bne get_input_room_oserr
  SET_AS_PLAYER                 ; Loads pointer to conn room data in TMP_ADDR_A
  lda FUNC_RES_L                ; Only need the low byte of the result
  dec A                         ; Internal room is one less
  sta ROOM_NUM
  jsr check_connecting_rooms    ; Result is in FUNC_RESULT
  lda FUNC_RESULT
  beq get_input_room_err        ; 0 means no match
  jmp get_input_room_end
.get_input_room_err
  lda #ERR_ROOM_NOT_REACHABLE
  sta FUNC_ERR
  jmp get_input_room_end
.get_input_room_oserr
  lda #ERR_OS_ERROR
  sta FUNC_ERR
.get_input_room_end
  rts

\ ------------------------------------------------------------------------------
\ ---  INIT_CHECK_UNIQUE
\ ------------------------------------------------------------------------------
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

\ ------------------------------------------------------------------------------
\ --- LIST_LOCS
\ ------------------------------------------------------------------------------
;.list_locs                ; FOR DEBUGGING ONLY
;  ldx #0
;.list_locs_loop
;  lda RANDOM_LOCS,X
;  jsr OSB2HEX
;  jsr OSWRSBUF
;  lda #' '
;  jsr OSWRCH
;  inx
;  cpx #NUM_LOCS
;  beq list_locs_done
;  jmp list_locs_loop
;.list_locs_done
;  lda #CHR_LINEEND
;  jsr OSWRCH
;  rts

\ ------------------------------------------------------------------------------
\ ---  PRINT_ROOM_NUM
\ ------------------------------------------------------------------------------
.print_room_num ; location in A
  inc A
  jsr OSB2ISTR
  jsr OSWRSBUF
  rts

\ ------------------------------------------------------------------------------
\ ---  RANDOM_ROOM
\ ------------------------------------------------------------------------------
\ ON ENTRY: Room number in ROOM_NUM
\ ON EXIT : New random room number in ROOM_NUM
.random_room
  lda #<R_CONN_ROOMS
  sta TMP_ADDR_A_L
  lda #>R_CONN_ROOMS
  sta TMP_ADDR_A_H
  lda ROOM_NUM
  jsr find_adjacent_rooms     ; 3 bytes with conn room nums now in R_CONN_ROOMS
  ldx #3                      ; Divisor for MOD
  jsr roll_dice               ; Random number in A
  tax
  lda R_CONN_ROOMS,X
  sta ROOM_NUM
  rts

\ ------------------------------------------------------------------------------
\ ---  ROLL_DICE
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

\ ------------------------------------------------------------------------------
\ ---  SET_PLAYER_CONNECTING_ROOMS
\ ------------------------------------------------------------------------------
.set_player_connecting_rooms
  lda #<P_CONN_ROOMS
  sta TMP_ADDR_A
  lda #>P_CONN_ROOMS
  sta TMP_ADDR_A+1
  lda PLAYER_LOC
  jsr find_adjacent_rooms
  rts

\ ------------------------------------------------------------------------------
\ ---  SHOW_CONNECTING_ROOMS
\ ------------------------------------------------------------------------------
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

\ ------------------------------------------------------------------------------
\ ---  SHOW_CURRENT_ROOM
\ ------------------------------------------------------------------------------
.show_current_room
  LOAD_MSG current_room_msg
  jsr OSWRMSG
  lda PLAYER_LOC
  jsr print_room_num
  NEWLINE
  rts

\ ------------------------------------------------------------------------------
\ ---  SHOW_ERROR_MSG
\ ------------------------------------------------------------------------------
.show_error_msg
  lda FUNC_ERR
  dec A                   ; To get offset for table
  asl A                   ; Shift left to multiply by 2
  tax                     ; Move to X to use as offset
  lda error_msg_ptrs,X    ; Get LSB of relevant address from the cmd_ptrs table
  sta MSG_VEC             ; and put in MSG_VEC
  lda error_msg_ptrs+1,X  ; Get MSB
  sta MSG_VEC+1           ; and put in MSG_VEC high byte
  jsr OSWRMSG
  stz FUNC_ERR
  rts

\ ------------------------------------------------------------------------------
\ ---  STAPLE_COUNT
\ ------------------------------------------------------------------------------
.staple_count
  lda STAPLE_COUNT
  pha
  LOAD_MSG staple_count_msg
  jsr OSWRMSG
  pla
;  clc
;  adc #$30                            ; To get ASCII char
;  jsr OSWRCH
;  lda #' '
;  jsr OSWRCH
  ldx STAPLE_COUNT
.staple_loop
  lda #91                             ; Open square bracket
  jsr OSWRCH
  dex
  bne staple_loop
  rts

\ ------------------------------------------------------------------------------
\ ---  STATUS_MSG
\ ------------------------------------------------------------------------------
.status_msg
  jsr show_current_room
  jsr set_player_connecting_rooms
  jsr show_connecting_rooms
  jsr staple_count
  NEWLINE
  jsr warnings
  jsr debug_locations
  rts

.debug_locations
  lda #'Z'
  jsr OSWRCH
  lda #':'
  jsr OSWRCH
  lda ZUMPUS_LOC
  jsr print_room_num
  lda #' '
  jsr OSWRCH

  lda #'B'
  jsr OSWRCH
  lda #':'
  jsr OSWRCH
  lda BAT1_LOC
  jsr print_room_num
   lda #' '
  jsr OSWRCH

  lda #'B'
  jsr OSWRCH
  lda #':'
  jsr OSWRCH
  lda BAT2_LOC
  jsr print_room_num
  lda #' '
  jsr OSWRCH

  lda #'P'
  jsr OSWRCH
  lda #':'
  jsr OSWRCH
  lda PIT1_LOC
  jsr print_room_num
  lda #' '
  jsr OSWRCH

  lda #'P'
  jsr OSWRCH
  lda #':'
  jsr OSWRCH
  lda PIT2_LOC
  jsr print_room_num
  NEWLINE
  rts

\ ------------------------------------------------------------------------------
\ ---  STATUS_UPDATE
\ ------------------------------------------------------------------------------
.status_update
  ; Check for threats.
  stz SITUATION
  lda PLAYER_LOC
  cmp ZUMPUS_LOC
  beq dead_as_a_dead_thing
  cmp PIT1_LOC
  beq down_the_pit
  cmp PIT2_LOC
  beq down_the_pit
  cmp BAT1_LOC
  beq status_kidnapped
  cmp BAT2_LOC
  beq status_kidnapped
  lda STAPLE_COUNT
  beq out_of_staples
  jmp status_update_end
.dead_as_a_dead_thing
  lda #STATE_DEAD
  sta SITUATION
  jmp status_update_end
.down_the_pit
  lda #STATE_FALLEN
  sta SITUATION
  jmp status_update_end
.status_kidnapped
  lda #STATE_KIDNAPPED
  sta SITUATION
  jmp status_update_end
.out_of_staples
  lda #STATE_NO_STAPLES
  sta SITUATION
.status_update_end
  rts

\ ------------------------------------------------------------------------------
\ ---  WARNINGS
\ ------------------------------------------------------------------------------
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
.warning_next
  inx
  cpx #3
  beq warnings_done
  jmp warning_loop
.warnings_done
  rts

\ ---  YESNO
\ ON ENTRY: SHould probably have zeroed-out STDIN_BUF and STDIN_IDX.
\ ON EXIT : A contains result, YESNO_YES, YESNO_NO, YESNO_ERR
.yesno
  lda STDIN_STATUS_REG
  and #STDIN_NUL_RCVD_FLG               ; Is the 'null received' bit set?
  beq yesno                             ; If no, wait
  stz STDIN_IDX                         ; Want to get first char
  jsr OSRDCH
  ; --- DEBUGGING ------------------
;  lda FUNC_RESULT
;  jsr OSWRCH
;  lda #' '
;  jsr OSWRCH
  ; --------------------------------
  lda FUNC_RESULT
  cmp #'Y'
  beq yesno_yes
  cmp #'N'
  beq yesno_no
  lda #YESNO_ERR
  jmp yesno_done
.yesno_yes
  lda #YESNO_YES
  sta BARLED_DAT
  jmp yesno_done
.yesno_no
  lda #YESNO_NO
.yesno_done
  sta FUNC_RESULT
  stz STDIN_IDX
  stz STDIN_BUF
  lda STDIN_STATUS_REG                    ; Get our info register
  eor #STDIN_NUL_RCVD_FLG                 ; Zero the received flag
  sta STDIN_STATUS_REG                    ; and re-save the register
  rts

