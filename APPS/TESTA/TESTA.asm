; Code for Zolatron 64 6502-based microcomputer.
;
; GitHub: https://github.com/mspeculatrix/Zolatron64/
; Blog: https://mansfield-devine.com/speculatrix/category/projects/zolatron/
;
; Written for the Beebasm assembler
; Assemble with:
; beebasm -v -i TESTA.asm

CPU 1                               ; use 65C02 instruction set

INCLUDE "../../LIB/cfg_main.asm"
INCLUDE "../../LIB/cfg_page_0.asm"
; PAGE 1 is the STACK
INCLUDE "../../LIB/cfg_page_2.asm"
; PAGE 3 is used for STDIN & STDOUT buffers, plus indexes
INCLUDE "../../LIB/cfg_page_4.asm"
INCLUDE "../../LIB/cfg_parallel.asm"

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
  equs "TESTA",0            ; @ $080D Short name, max 15 chars - nul terminated
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

  LOAD_MSG start_msg
  jsr OSWRMSG
  jsr OSLCDMSG

  stz STDOUT_IDX                              ; Set offset pointer
  LOAD_MSG load_initial_msg
  jsr OSSOAPP                                 ; Add to STDOUT_BUF
  lda PRLL_DATA_DDR
  sta TMP_VAL
  jsr print_byte

  ldx #0
.test_loop
  phx
  stz STDOUT_IDX                              ; Set offset pointer
  LOAD_MSG write_msg
  jsr OSSOAPP                                 ; Add to STDOUT_BUF
  lda test_vals,X
  beq loop_done
  sta TEST_VAL
  sta PRLL_DATA_DDR
  jsr print_byte

  stz STDOUT_IDX                              ; Set offset pointer
  LOAD_MSG read_msg
  jsr OSSOAPP                                 ; Add to STDOUT_BUF
  lda PRLL_DATA_DDR
  cmp TEST_VAL
  bne match_failed
  jsr print_byte
  plx
  inx
  jmp test_loop
.match_failed
  LOAD_MSG match_fail_msg
  jsr OSWRMSG
  NEWLINE
  jmp prog_end
.loop_done
  stz STDOUT_IDX                              ; Set offset pointer
  LOAD_MSG restore_msg
  jsr OSSOAPP                                 ; Add to STDOUT_BUF
  lda TMP_VAL
  sta PRLL_DATA_DDR
  jsr print_byte

.prog_end
  stz STDIN_IDX                           ; Clear input buffer
  stx STDIN_BUF
  lda STDIN_STATUS_REG                    ; Get our info register
  and #STDIN_CLEAR_FLAGS                  ; Clear the received flags
  sta STDIN_STATUS_REG                    ; and re-save the register
  jmp OSSFTRST

.print_byte
  jsr OSB2HEX                                 ; Result will be in STR_BUF
  STR_BUF_TO_MSG_VEC                          ; Set MSG_VEC to point to this
  jsr OSSOAPP                                 ; Add to STDOUT_BUF
  jsr OSWRBUF
  NEWLINE
  rts

.start_msg
  ;     12345678901234567890
  equs "Parallel port test",10,0
.load_initial_msg
  equs "Initial value     : ",0
.write_msg
  equs "Writing           : ",0
.read_msg
  equs "Read back         : ",0
.restore_msg
  equs "Restoring init val: ",0
.match_fail_msg
  equs "Match failed",0
.test_vals
  equs %01010101, %10101010, $FF, %11110000, %00001111, 0

.endtag
  equs "EOF",0
.endcode

SAVE "../bin/TESTA.EXE", header, endcode
