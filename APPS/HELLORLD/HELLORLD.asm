; Code for Zolatron 64 6502-based microcomputer.
;
; GitHub: https://github.com/mspeculatrix/Zolatron64/
; Blog: https://mansfield-devine.com/speculatrix/category/projects/zolatron/
;
; Written for the Beebasm assembler
; Assemble with:
; beebasm -v -i TESTA.asm

CPU 1                               ; use 65C02 instruction set

BARLED = $0230				      ; for the bar LED display
BARLED_L = BARLED
BARLED_H = BARLED + 1

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
  equb <header              ; @ $0802 Entry address
  equb >header
  equb <reset               ; @ $0804 Reset address
  equb >reset
  equb <endcode             ; @ $0806 Addr of first byte after end of program
  equb >endcode
  equs 0,0,0                ; -- Reserved for future use --
.prog_name
  equs "HELLORLD",0            ; @ $080D Short name, max 15 chars - nul terminated
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

  jsr OSLCDCLS

.main

  jsr OSLCDCLS

  LOAD_MSG cons_message
  jsr OSWRMSG
  LOAD_MSG lcd_message
  jsr OSLCDMSG
  jsr press_key


.prog_end
  stz STDIN_IDX                           ; Clear input buffer
  stx STDIN_BUF
  lda STDIN_STATUS_REG                    ; Get our info register
  and #STDIN_CLEAR_FLAGS                  ; Clear the received flags
  sta STDIN_STATUS_REG                    ; and re-save the register
  jmp OSSFTRST


.press_key                              ; Returns key in FUNC_RESULT
  pha
.press_key_loop
  lda STDIN_STATUS_REG
  and #STDIN_NUL_RCVD_FL                ; Is the 'null received' bit set?
  beq press_key_loop                ; If no, loop until it is
.press_key_done
  stz STDIN_IDX                         ; Want to get first char
  jsr OSRDCH                            ; Read character from STDIN_BUF
  pla
  rts

.cons_message
  ;     12345678901234567890
  equs 10,"HELLORLD!",10,10,"SHALL WE PLAY A GAME?",10,10,'>',0
.lcd_message
  ;     12345678901234567890
  equs "HELLORLD!",10,10
  equs "SHALL WE PLAY A",10,"GAME?",0

.endtag
  equs "EOF",0
.endcode

SAVE "../bin/HELLORLD.EXE", header, endcode
