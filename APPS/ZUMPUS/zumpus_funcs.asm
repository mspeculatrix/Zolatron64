; zumpus_funcs.asm

\ ------------------------------------------------------------------------------
\ ---  CHECK_CONNECTING_ROOMS
\ ------------------------------------------------------------------------------
\ Check whether the room number in ROOM_NUM is a valid connecting room.
\ Assumes the three bytes containing valid room numbers start at
\ the address pointed to by TMP_ADDR_A. So this is typically called after using
\ find_adjacent_rooms.
\ ON ENTRY: ROOM_NUM contains room number to check
\ ON EXIT : FUNC_RESULT contains 0 = invalid room, 1 = valid room
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
\ Get a list of the rooms adjacent to the current one.
\ Assumes the three bytes to which you want to store the room numbers start at
\ the address pointed to by TMP_ADDR_A.
\ ON ENTRY: - A must contain current room number.
\           - TMP_ADDR_A/+1 mus contain pointer to address where you want to
\             store the results.
\ ON EXIT : Results stored in three byytes pointed to by TMP_ADDR_A.
.find_adjacent_rooms
  clc
  asl A                                 ; Need to multiply by 4 for lookup table
  asl A                                 ; offset.
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
\ a connecting room.
\ ON ENTRY: Expecting a room number to be next item in STDIN_BUF
\ ON EXIT : - Room number is in ROOM_NUM
\           - Error is in FUNC_ERR
.get_input_room
  stz FUNC_ERR                  ; Set default
  jsr OSRDINT16                 ; Read the room number from STDIN_BUF
  lda FUNC_ERR                  ; Check for error
  bne get_input_room_oserr
  lda #<P_CONN_ROOMS            ; Load pointer to conn room data in TMP_ADDR_A
  sta TMP_ADDR_A                ;  "
  lda #>P_CONN_ROOMS            ;  "
  sta TMP_ADDR_A + 1            ;  "
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
\ Used when setting up game and assigning random locations to the various
\ characters. This basically ensures that each character is assigned a
\ different room.
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
\ ON ENTRY: Room number in A
.print_room_num
  inc A                 ; Because internal room numbers are one less than
  jsr OSB2ISTR          ; those shown to the player.
  jsr OSWRSBUF
  rts

\ ------------------------------------------------------------------------------
\ ---  RANDOM_ROOM
\ ------------------------------------------------------------------------------
\ Select a random connecting room.
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
  tax                         ; Use random number as an offset
  lda R_CONN_ROOMS,X          ; and select from connecting rooms
  sta ROOM_NUM
  rts

\ ------------------------------------------------------------------------------
\ ---  ROLL_DICE
\ ---  Get a random number.
\ ------------------------------------------------------------------------------
\ Generates a random number in the range 0..59 simply by looking at the value
\ of the timer counter. This value is then MODded by whatever is in X. So:
\     X=2   Returns 0 or 1 - ie, false or true
\     X=3   Returns 0, 1 or 2
\     X=4   Returns 0, 1, 2 or 3
\     X=20  Returns 0-19 - for choosing a random room number.
\ ON ENTRY: X must contain the divisor for MODding.
\ ON EXIT : A will contain the actual value of the counter MODded by X.
\ ------------------------------------------------------------------------------
.roll_dice
  lda USRP_T1CL           ; Get the current counter value
  cmp #$FF                ; Sometimes this pops up - don't know why
  bne roll_dice_mod       ; If it doesn't, we're good to go
  jmp roll_dice           ; Otherwise, try again
.roll_dice_mod
  jsr uint8_mod8          ; A contains random number, X contains divisor
  lda FUNC_RESULT         ; Get the result of the MODding.
  rts

\ ------------------------------------------------------------------------------
\ ---  SET_PLAYER_CONNECTING_ROOMS
\ ------------------------------------------------------------------------------
\ Set a pointer to the array of rooms that connect to the Player's current
\ location.
\ ON EXIT : TMP_ADDR_A/+1 contains pointer to the P_CONN_ROOMS array
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
\ Print a list of the rooms that connect to the Player's current location.
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
\ Print the number of the Player's current location.
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
\ Print an error message. Looks up message from the Error Message Table
\ according to an error code in FUNC_ERR
\ ON ENTRY: Error code must be in FUNC_ERR
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
\ Print a message telling the Player how many staples remain.
.staple_count
  lda STAPLE_COUNT
  pha
  LOAD_MSG staple_count_msg
  jsr OSWRMSG
  pla
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
\ Print a status update. Run at the end of every turn.
.status_msg
  jsr show_current_room
  jsr set_player_connecting_rooms
  jsr show_connecting_rooms
  jsr staple_count
  NEWLINE
  jsr warnings
;  jsr debug_locations
  rts

\ ------------------------------------------------------------------------------
\ ---  DEBUG_LOCATIONS - for debugging only
\ ------------------------------------------------------------------------------
;.debug_locations
;  lda #'Z'
;  jsr OSWRCH
;  lda #':'
;  jsr OSWRCH
;  lda ZUMPUS_LOC
;  jsr print_room_num
;  lda #' '
;  jsr OSWRCH

;  lda #'S'
;  jsr OSWRCH
;  lda #':'
;  jsr OSWRCH
;  lda Z_STATE
;  jsr OSB2ISTR
;  jsr OSWRSBUF
;  lda #' '
;  jsr OSWRCH

;  lda #'B'
;  jsr OSWRCH
;  lda #':'
;  jsr OSWRCH
;  lda BAT1_LOC
;  jsr print_room_num
;   lda #' '
;  jsr OSWRCH

;  lda #'B'
;  jsr OSWRCH
;  lda #':'
;  jsr OSWRCH
;  lda BAT2_LOC
;  jsr print_room_num
;  lda #' '
;  jsr OSWRCH

;  lda #'P'
;  jsr OSWRCH
;  lda #':'
;  jsr OSWRCH
;  lda PIT1_LOC
;  jsr print_room_num
;  lda #' '
;  jsr OSWRCH

;  lda #'P'
;  jsr OSWRCH
;  lda #':'
;  jsr OSWRCH
;  lda PIT2_LOC
;  jsr print_room_num
;  NEWLINE
;  rts

\ ------------------------------------------------------------------------------
\ ---  STATUS_UPDATE
\ ------------------------------------------------------------------------------
\ Update the status of the Player - checking, for example, whether the Player
\ has entered a room containing Zumpus, a sales rep (bat) or a lift shaft (pit).
\ Also checks how many staples are left.
\ ON EXIT : Sets P_CONDITION
.status_update
  ; Check for threats.
  stz P_CONDITION                 ; Reset to default
  lda PLAYER_LOC                  ; Are we in a room with Zumpus?
  cmp ZUMPUS_LOC                  ;  "
  beq dead_as_a_dead_thing        ;  "
  cmp PIT1_LOC                    ; Are we in a room with a lift shaft?
  beq down_the_pit                ;  "
  cmp PIT2_LOC                    ;  "
  beq down_the_pit                ;  "
  cmp BAT1_LOC                    ; Are we in a room with a sales rep?
  beq status_kidnapped            ;  "
  cmp BAT2_LOC                    ;  "
  beq status_kidnapped            ;  "
  lda STAPLE_COUNT                ; Have we run out of staples?
  beq out_of_staples              ;  "
  jmp status_update_end           ; If none of above, we're done here
.dead_as_a_dead_thing
  lda #STATE_DEAD
  sta P_CONDITION
  jmp status_update_end
.down_the_pit
  lda #STATE_FALLEN
  sta P_CONDITION
  jmp status_update_end
.status_kidnapped
  lda #STATE_KIDNAPPED
  sta P_CONDITION
  jmp status_update_end
.out_of_staples
  lda #STATE_NO_STAPLES
  sta P_CONDITION
.status_update_end
  rts

\ ------------------------------------------------------------------------------
\ --- FILE OPERATIONS
\ ------------------------------------------------------------------------------


.set_datafile
  ldx #0                              ; Set filename
.set_datafile_loop
  lda game_data_file,X
  sta STR_BUF,X
  inx
  cmp #0
  bne set_datafile_loop
  rts

.read_gamedata
  stz FUNC_ERR
  lda #<DATA_START                    ; Set location for loading data
  sta FILE_ADDR
  lda #>DATA_START
  sta FILE_ADDR + 1
  jsr set_datafile                    ; Set data filename
  lda #ZD_OPCODE_DLOAD                ; Set opcode for loading data
  jsr OSZDLOAD                        ; Load data
  lda FUNC_ERR
  beq read_gamedata_success
  jsr OSWRERR                         ; For debugging
  NEWLINE
  LOAD_MSG readdata_failed_msg
  jmp read_gamedata_end
.read_gamedata_success
  LOAD_MSG readdata_success_msg
.read_gamedata_end
  jsr OSWRMSG
  rts

.write_gamedata
  stz FUNC_ERR
  lda #<DATA_START                    ; Set start location of data
  sta TMP_ADDR_A
  lda #>DATA_START
  sta TMP_ADDR_A + 1
  lda #<DATA_END                      ; Set end location of data
  sta TMP_ADDR_B
  lda #>DATA_END
  sta TMP_ADDR_B + 1
  jsr set_datafile                    ; Set data filename
  lda #ZD_OPCODE_SAVE_DATO            ; Set opcode for saving data
  jsr OSZDSAVE                        ; Save data
  lda FUNC_ERR
  beq write_gamedata_success
  LOAD_MSG writedata_failed_msg
  jmp write_gamedata_end
.write_gamedata_success
  LOAD_MSG writedata_success_msg
.write_gamedata_end
  jsr OSWRMSG
  rts

\ ------------------------------------------------------------------------------
\ ---  SHOW_STATS
\ ------------------------------------------------------------------------------
.show_stats
  stz STDOUT_IDX
  LOAD_MSG games_played_msg
  jsr OSSOAPP
  lda #' '
  jsr OSSOCH
  lda GAMES_PLAYED
  cmp #$FF
  beq show_stats_many_games
  jsr OSB2ISTR
  STR_BUF_TO_MSG_VEC
  jmp show_stats_games
.show_stats_many_games
  LOAD_MSG many_games_str
.show_stats_games
  jsr OSSOAPP
  jsr OSWRBUF
  NEWLINE
  stz STDOUT_IDX
  LOAD_MSG games_won_msg
  jsr OSSOAPP
  lda #' '
  jsr OSSOCH
  lda GAMES_WON
  cmp #$FF
  beq show_stats_many_won
  jsr OSB2ISTR
  STR_BUF_TO_MSG_VEC
  jmp show_stats_won
.show_stats_many_won
  LOAD_MSG many_games_str
.show_stats_won
  jsr OSSOAPP
  jsr OSWRBUF
  NEWLINE
  rts

\ ------------------------------------------------------------------------------
\ ---  WARNINGS
\ ------------------------------------------------------------------------------
\ Display warnings about being in a room adjacent to Zumpus, a sales rep or a
\ lift shaft.
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

\ ------------------------------------------------------------------------------
\ ---  YESNO
\ ------------------------------------------------------------------------------
\ Get a 'Y' or 'N' input.
\ ON ENTRY: Should probably have zeroed-out STDIN_BUF and STDIN_IDX before
\           coming here.
\ ON EXIT : A contains result, YESNO_YES, YESNO_NO or YESNO_ERR
.yesno
  lda STDIN_STATUS_REG
  and #STDIN_NUL_RCVD_FL                ; Is the 'null received' bit set?
  beq yesno                             ; If no, loop until it is
  stz STDIN_IDX                         ; Want to get first char
  jsr OSRDCH                            ; Read character from STDIN_BUF
  ; --- DEBUGGING ------------------
;  lda FUNC_RESULT
;  jsr OSWRCH
;  lda #' '
;  jsr OSWRCH
  ; --------------------------------
  lda FUNC_RESULT                       ; Check the character we read
  cmp #'Y'
  beq yesno_yes
  cmp #'N'
  beq yesno_no
  lda #YESNO_ERR                        ; If no 'Y' or 'N', this is an error
  jmp yesno_done
.yesno_yes
  lda #YESNO_YES
  jmp yesno_done
.yesno_no
  lda #YESNO_NO
.yesno_done
  sta FUNC_RESULT
  stz STDIN_IDX                         ; Clear input buffer
  stz STDIN_BUF                         ;  "
  lda STDIN_STATUS_REG                    ; Get our info register
  and #STDIN_CLEAR_FLAGS                  ; Clear the received flags
  sta STDIN_STATUS_REG                    ; and re-save the register
  rts
