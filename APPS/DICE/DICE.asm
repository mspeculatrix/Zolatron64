\ For playing around the random number generation for games

CPU 1                               ; use 65C02 instruction set

YESNO_ERR        = 0
YESNO_NO         = 1
YESNO_YES        = 2

INCLUDE "../../LIB/cfg_main.asm"
INCLUDE "../../LIB/cfg_page_0.asm"
; PAGE 1 is the STACK
INCLUDE "../../LIB/cfg_page_2.asm"
; PAGE 3 is used for STDIN & STDOUT buffers, plus indexes
INCLUDE "../../LIB/cfg_page_4.asm"
INCLUDE "../../LIB/cfg_user_port.asm"


ORG USR_START
.header                     ; HEADER INFO
  jmp startprog             ;
  equb "E"                  ; Designate executable file
  equb <header              ; Entry address
  equb >header
  equb <reset               ; Reset address
  equb >reset
  equb <endcode             ; Addr of first byte after end of program
  equb >endcode
  equs 0,0,0                ; -- Reserved for future use --
.prog_name
  equs "DICE",0           ; @ $080D Short name, max 15 chars - nul terminated
.version_string
  equs "1.0",0              ; Version string - nul terminated

.startprog
.reset
  sei             ; don't interrupt me yet
  cld             ; we don' need no steenkin' BCD
  ldx #$ff        ; set stack pointer to $01FF - only need to set the
  txs             ; LSB, as MSB is assumed to be $01

  lda #0
  sta PRG_EXIT_CODE
  cli

  jsr prng_start_timer        ; Start user timer in free-running mode.

.begin
  LOAD_MSG start_msg
  jsr OSWRMSG
  jsr OSGETKEY
  jsr prng_set_seed

  NEWLINE

  ldy #5
.loop
  jsr prng_rand8          ; Puts result in RAND_SEED
  lda RAND_SEED
  jsr OSB2ISTR
  jsr OSWRSBUF
  lda #' '
  jsr OSWRCH

  lda RAND_SEED
  ldx #20                 ; Divisor for mod operation
  jsr uint8_div8          ; A contains random number, X contains divisor
  lda FUNC_RESULT         ; Get the result of the MODding.
  jsr OSB2ISTR
  jsr OSWRSBUF
  NEWLINE
  dey
  bne loop

  jmp begin

.prog_end
  jmp OSSFTRST

\ ------------------------------------------------------------------------------
\ ---  *****   FUNCTIONS   *****
\ ------------------------------------------------------------------------------
INCLUDE "../../LIB/funcs_math.asm"
INCLUDE "../../LIB/funcs_prng.asm"

\ ------------------------------------------------------------------------------
\ ---  YESNO
\ ------------------------------------------------------------------------------
\ Get a 'Y' or 'N' input.
\ ON EXIT : A contains result, YESNO_YES, YESNO_NO or YESNO_ERR
.yesno
  stz STDIN_BUF
  stz STDIN_IDX
.yesno_loop
  lda STDIN_STATUS_REG
  and #STDIN_NUL_RCVD_FL                ; Is the 'null received' bit set?
  beq yesno_loop                        ; If no, loop until it is
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

.start_msg
  equs 10, "Press <return>",0
.seed_msg
  equs "Random seed: ",0

.endtag
  equs "EOF",0
.endcode

SAVE "../bin/DICE.EXE", header, endcode
