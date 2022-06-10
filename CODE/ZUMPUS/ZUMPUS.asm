; Code for Zolatron 64 6502-based microcomputer.
;
; GitHub: https://github.com/mspeculatrix/Zolatron64/
; Blog: https://mansfield-devine.com/speculatrix/category/projects/zolatron/
;
; Written for the Beebasm assembler
; Assemble with:
; beebasm -v -i ZUMPUS.asm

CPU 1                               ; use 65C02 instruction set

INCLUDE "../../LIB/cfg_main.asm"
INCLUDE "../../LIB/cfg_page_0.asm"
; PAGE 1 is the STACK
INCLUDE "../../LIB/cfg_page_2.asm"
; PAGE 3 is used for STDIN & STDOUT buffers, plus indexes
INCLUDE "../../LIB/cfg_page_4.asm"
INCLUDE "../../LIB/cfg_VIAC.asm"

INCLUDE "zumpus_cfg.asm"

ORG USR_PAGE
.header                     ; HEADER INFO
  jmp startprog             ;
  equw header               ; @ $0804 Entry address
  equw reset                ; @ $0806 Reset address
  equw endcode              ; @ $0808 Addr of first byte after end of program
  equs 0,0,0,0              ; -- Reserved for future use --
  equs "ZUMPUS",0           ; @ $080D Short name, max 15 chars - nul terminated
.version_string
  equs "0.1",0              ; Version string - nul terminated

.startprog
.reset                      ; Sometimes this may be different from startprog
  sei                       ; Don't interrupt me yet
  cld                       ; Ensure BCD mode is off
  ldx #$ff                  ; Set stack pointer to $01FF - only need to set the
  txs                       ; LSB, as MSB is assumed to be $01

  lda #0
  sta PRG_EXIT_CODE         ; Not sure we're using this yet
  cli

  stz VIAC_PORTA
  stz VIAC_PORTB

  lda #NUM_STAPLES
  sta STAPLE_COUNT

; Using Timer 1 for random numbers. Basically, this will run constantly in
; free-run mode, counting down constantly 59..0. So we're going to use it like
; a complex dice. Whenever we need to throw the dice, we just read the state of
; the counter. We'll only ever need to check the low byte. We can MOD the number
; by various factors - eg, 20 to get a random room number, 3 to get a random
; choice of connecting rooms.
  lda #%01000000		          ; Bit 7 off - don't need interrupts
  sta VIAC_IER
  lda #%01000000              ; Set timer to free-run mode
  sta VIAC_ACL			
  lda #59                     ; Start value
  sta VIAC_T1CL
  lda #0
  sta VIAC_T1CH		            ; Starts timer running

.main
  stz STDIN_BUF
  stz STDIN_IDX
  NEWLINE
.instruction_prompt
  LOAD_MSG instr_prompt
  jsr OSWRMSG
  jsr yesno
  ; --- DEBUGGING ------------------
;  lda FUNC_RESULT
;  jsr OSB2ISTR
;  jsr OSWRSBUF
;  lda #' '
;  jsr OSWRCH
  ; --------------------------------
  lda FUNC_RESULT
  cmp #YESNO_YES
  bne init
  
  LOAD_MSG start_msg
  jsr OSWRMSG
  NEWLINE
  LOAD_MSG instructions
  jsr OSWRMSG
  NEWLINE

.init
  stz BARLED_CMD
  stz BARLED_DAT
  LOAD_MSG init_msg
  jsr OSWRMSG
  NEWLINE
  stz SITUATION
  lda #5
  sta STAPLE_COUNT
; Randomise initial locations of player & threats
  ldy #0      ; Counter for number of locs we've set
.init_loop
  LOAD_MSG press_enter_msg
  jsr OSWRMSG
.init_loop_wait
  lda STDIN_STATUS_REG
  and #STDIN_NUL_RCVD_FLG
  bne init_set_loc
  jmp init_loop_wait
.init_set_loc
  ldx #NUM_ROOMS                ; MOD
  phy
  jsr roll_dice                 ; Random number will be in A
  ply
  sta RANDOM_LOCS,Y
  stz STDIN_IDX                 ; Clear the input buffer
  lda STDIN_STATUS_REG          ; Reset the nul received flag
  and #STDIN_CLEAR_FLAGS
  sta STDIN_STATUS_REG
  jsr init_check_unique         ; Check that this number not already used
  lda FUNC_RESULT
  bne init_loop
  iny
  cpy #NUM_LOCS
  beq init_done
  jmp init_loop
.init_done
  lda #CHR_LINEEND
  jsr OSWRCH
  jmp start_play

.start_play
;  jsr list_locs
  NEWLINE
  jsr status_update
  jsr status_msg
  LOAD_MSG zumpus_prompt
  jsr OSWRMSG

\ ------------------------------------------------------------------------------
\ ---  MAINLOOP
\ ------------------------------------------------------------------------------
.mainloop
  lda STDIN_STATUS_REG
  and #STDIN_NUL_RCVD_FLG               ; Is the 'null received' bit set?
  bne zum_input                         ; If yes, process the buffer
  ldx STDIN_IDX                         ; Load the value of the RX buffer index
  cpx #STR_BUF_LEN                      ; Are we at the limit?
  bcs zum_input                         ; Branch if X >= STR_BUF_LEN
  jmp mainloop

.zum_input
  ; Okay, so there's stuff in the input buffer. Let's take a look.
  lda STDIN_STATUS_REG                    ; Get our info register
  eor #STDIN_NUL_RCVD_FLG                 ; Zero the received flag
  sta STDIN_STATUS_REG                    ; and re-save the register
  stz STDIN_IDX

  ; We're expecting the first item to be 'M', 'S' or 'Q'
  jsr OSRDCH
  lda FUNC_RESULT
  cmp #'I'
  beq zum_cmd_instructions
  cmp #'M'
  beq zum_cmd_move
  cmp #'S'
  beq zum_cmd_shoot
  cmp #'Q'
  beq zum_cmd_leave
  lda #ERR_SYNTAX
  sta FUNC_ERR
  jsr show_error_msg
  jmp zum_chk_stat
.zum_cmd_leave
  jmp zum_cmd_quit
; ---  INSTRUCTIONS ------------------------------------------------------------
.zum_cmd_instructions
  LOAD_MSG instructions
  jsr OSWRMSG
  NEWLINE
  jmp zum_chk_stat
; ---  MOVING ------------------------------------------------------------------
.zum_cmd_move
  jsr get_input_room
  lda FUNC_ERR
  bne zum_cmd_move_err
  lda ROOM_NUM
  sta PLAYER_LOC
  ;NEWLINE
  jmp zum_cmd_move_end
.zum_cmd_move_err
  jsr show_error_msg
  jmp zum_input_go_again
.zum_cmd_move_end
  jmp zum_chk_stat

; ---  SHOOTING ----------------------------------------------------------------
.zum_cmd_shoot
  ; The input buf should contain the room number & range of shot
  jsr get_input_room            ; Puts room in ROOM_NUM
  lda FUNC_ERR
  bne zum_cs_err_msg
  jsr OSRDINT16                 ; Read range from STDIN_BUF, num in FUNC_RES_L
  lda FUNC_ERR                  ; Check for error
  bne zum_cs_oserr
  lda FUNC_RES_L
  beq zum_cs_range_err   ; 0 is not an option
  cmp #6
  bcs zum_cs_range_err
  jmp zum_cmd_shoot_staple
.zum_cs_err_msg
  jmp zum_cmd_shoot_err_msg
.zum_cs_oserr
  jmp zum_cmd_shoot_oserr
.zum_cs_range_err
  jmp zum_cmd_shoot_range_err
.zum_cmd_shoot_staple
  sta STAPLE_RANGE
;  dec STAPLE_RANGE              ; Immediately decr to account for first room
  dec STAPLE_COUNT              ; We have one fewer staples now
;  stz SHOT_STATE
.zum_cmd_shoot_flight
  ; --- DEBUGGING -----------------
  lda ROOM_NUM
  inc A
  jsr OSB2ISTR
  jsr OSWRSBUF
  lda #' '
  jsr OSWRCH
  ; -------------------------------
  lda ROOM_NUM
  cmp ZUMPUS_LOC
  beq zum_cmd_shoot_hit
  cmp PLAYER_LOC
  beq zum_cmd_shoot_self
  dec STAPLE_RANGE
  beq zum_cmd_shoot_missed
  jsr random_room
  jmp zum_cmd_shoot_flight
.zum_cmd_shoot_hit
  ldx #4                        ; Divisor for MOD
  jsr roll_dice                 ; A should contain value 0-3
  cmp #2
  bcs zum_cmd_shoot_win
  LOAD_MSG shot_nearhit_msg
  jsr OSWRMSG
  jmp zum_cmd_shoot_end
.zum_cmd_shoot_win
  LOAD_MSG shot_hit_msg
  jsr OSWRMSG
  jmp game_end
.zum_cmd_shoot_self
  ldx #6                        ; Divisor for MOD
  jsr roll_dice                 ; A should contain value 0-3
  cmp #3
  beq zum_cmd_shoot_selfhit
  LOAD_MSG shot_nearself_msg
  jsr OSWRMSG
  jmp zum_cmd_shoot_end
.zum_cmd_shoot_selfhit
  LOAD_MSG shot_self_msg
  jsr OSWRMSG
  jmp game_end
.zum_cmd_shoot_missed
  LOAD_MSG shot_miss_msg
  jsr OSWRMSG
  jmp zum_cmd_shoot_end
.zum_cmd_shoot_range_err
  lda #ERR_RANGE
  jmp zum_cmd_shoot_err_msg
.zum_cmd_shoot_oserr
  lda #ERR_OS_ERROR
.zum_cmd_shoot_err_msg
  sta FUNC_ERR
  jsr show_error_msg
  jmp zum_input_go_again

.zum_cmd_shoot_end
  jmp zum_chk_stat

; ---  QUIT --------------------------------------------------------------------
.zum_cmd_quit
  jmp prog_end

.zum_chk_stat
  LOAD_MSG breakline
  jsr OSWRMSG
.zum_input_status_chk
  jsr status_update
  lda SITUATION
  cmp #STATE_DEAD
  beq zum_fate_dead
  cmp #STATE_FALLEN
  beq zum_fate_fallen
  cmp #STATE_KIDNAPPED
  beq zum_input_kidnapped
  cmp #STATE_NO_STAPLES
  beq zum_fate_no_ammo
  jmp zum_input_go_again
.zum_fate_dead
  jmp you_have_died
.zum_fate_fallen
  jmp falling_down_the_pit
.zum_fate_no_ammo
  jmp zum_input_ammo_out
.zum_input_kidnapped
;  SHOW_STATE
  LOAD_MSG you_are_kidnapped
  jsr OSWRMSG
.zum_input_random_room
  ldx #NUM_ROOMS
  jsr roll_dice                         ; Random number will be in A
  cmp PLAYER_LOC                        ; Ensure we don't get taken to the
  beq zum_input_random_room             ; same place we are now, or to our
  cmp ZUMPUS_LOC                        ; immediate demise...
  beq zum_input_random_room             ;  "
  cmp BAT1_LOC                          ;  "
  beq zum_input_random_room             ;  "
  cmp BAT2_LOC                          ;  "
  beq zum_input_random_room             ;  "
  cmp PIT1_LOC                          ;  "
  beq zum_input_random_room             ;  "
  cmp PIT2_LOC                          ;  "
  beq zum_input_random_room             ;  "
  sta PLAYER_LOC
.zum_input_go_again
  jsr status_msg
  LOAD_MSG zumpus_prompt
  jsr OSWRMSG
  stz STDIN_BUF
  stz STDIN_IDX
  stz FUNC_ERR
  jmp mainloop
.you_have_died
  LOAD_MSG you_are_dead
  jsr OSWRMSG
  jmp game_end
.falling_down_the_pit
  LOAD_MSG you_have_fallen
  jsr OSWRMSG
  jmp game_end
.zum_input_ammo_out
  LOAD_MSG you_have_no_staples
  jsr OSWRMSG
.game_end
  stz STDIN_IDX
  stz STDIN_BUF
  LOAD_MSG go_again_msg
  jsr OSWRMSG
.game_end_yesno
  jsr yesno
  lda FUNC_RESULT
  cmp #YESNO_YES
  beq play_again
  cmp #YESNO_ERR
  beq play_again
  jmp prog_end
.play_again
  jmp init
.prog_end
  stz STDIN_IDX
  stz STDIN_BUF
  jmp OSSFTRST

INCLUDE "./zumpus_funcs.asm"
INCLUDE "./zumpus_data.asm"
INCLUDE "../../LIB/funcs_math.asm"

.endcode

SAVE "../bin/ZUMPUS.BIN", header, endcode
