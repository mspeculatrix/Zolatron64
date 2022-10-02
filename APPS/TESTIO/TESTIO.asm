; Code for Zolatron 64 6502-based microcomputer.
;
; GitHub: https://github.com/mspeculatrix/Zolatron64/
; Blog: https://mansfield-devine.com/speculatrix/category/projects/zolatron/
;
; Written for the Beebasm assembler
; Assemble with:
; beebasm -v -i TESTB.asm

CPU 1                               ; use 65C02 instruction set

INCLUDE "../../LIB/cfg_main.asm"
INCLUDE "../../LIB/cfg_page_0.asm"
; PAGE 1 is the STACK
INCLUDE "../../LIB/cfg_page_2.asm"
; PAGE 3 is used for STDIN & STDOUT buffers, plus indexes
INCLUDE "../../LIB/cfg_page_4.asm"

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
  equs "TESTIO",0           ; @ $080D Short name, max 15 chars - nul terminated
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

  ;lda #SEED_VAL
  ;sta RAND_SEED

  cli

.main
  LOAD_MSG welcome_msg
  jsr OSWRMSG
  lda #CHR_LINEEND
  jsr OSWRCH


.enter_loop
  LOAD_MSG enter_msg
  jsr OSWRMSG
  jsr os_getkey
  ;NEWLINE
  lda FUNC_RESULT
  jsr OSB2HEX
  jsr OSWRSBUF
  NEWLINE
;  lda FUNC_ERR
;  bne enter_error
  lda FUNC_RESULT
  beq enter_entered
  jsr OSWRCH
  jmp enter_loopback
.enter_error
  LOAD_MSG error_msg
  jsr OSWRMSG
  NEWLINE
  jmp prog_end
.enter_entered
  LOAD_MSG return_msg
  jsr OSWRMSG
.enter_loopback
  NEWLINE
  jmp enter_loop

.prog_end
  jmp OSSFTRST

\ --- FUNCTIONS ----------------------------------------------------------------
; Test code for possible OS function OSGETKEY
; Designed to return a single character
.os_getkey
  stz FUNC_ERR
  stz FUNC_RESULT
  stz STDIN_IDX                         ; Zero-out buffer
  stz STDIN_BUF
.os_getkey_loop
  lda STDIN_STATUS_REG
  and #STDIN_NUL_RCVD_FL                ; Is the 'null received' bit set?
  beq os_getkey_loop                    ; If no, loop until it is
  lda STDIN_BUF                         ; Read char from STDIN_BUF
  sta FUNC_RESULT
  lda STDIN_STATUS_REG                  ; Clear the STDIN flags in status reg
  and #STDIN_CLEAR_FLAGS
  sta STDIN_STATUS_REG
  stz STDIN_IDX                         ; Zero-out buffer
  stz STDIN_BUF
  rts

\ --- DATA ---------------------------------------------------------------------
.welcome_msg
  equs "TESTIO - experimenting with I/O code", 0

.enter_msg
  equs "Type a key + <ret>: ",0

.error_msg
  equs "Hmmm, what happened there?",0

.return_msg
  equs "<return>",0

.endtag
  equs "EOF",0
.endcode

SAVE "../bin/TESTIO.EXE", header, endcode
