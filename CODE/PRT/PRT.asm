; Code for Zolatron 64 6502-based microcomputer.
;
; GitHub: https://github.com/mspeculatrix/Zolatron64/
; Blog: https://mansfield-devine.com/speculatrix/category/projects/zolatron/
;
; Written for the Beebasm assembler
; Assemble with:
; beebasm -v -i PRT.asm

CPU 1                               ; use 65C02 instruction set

INCLUDE "../../LIB/cfg_main.asm"
INCLUDE "../../LIB/cfg_page_0.asm"
; PAGE 1 is the STACK
INCLUDE "../../LIB/cfg_page_2.asm"
; PAGE 3 is used for STDIN & STDOUT buffers, plus indexes
INCLUDE "../../LIB/cfg_page_4.asm"
;INCLUDE "../../LIB/cfg_parallel.asm"
INCLUDE "../../LIB/cfg_prt.asm"


MACRO LCDG_SET_CTL ctl_bits        ; set control bits for LCD
  lda USRP_CTRL                  ; load the current state of PORT A
;  and #LED_MASK                   ; clear the top three bits
  ora #ctl_bits                   ; set those bits. Lower 5 bits should be 0s
  sta USRP_CTRL                  ; store result
ENDMACRO

ORG USR_PAGE
.header                     ; HEADER INFO
  jmp startprog             ;
  equw header               ; @ $0803 Entry address
  equw reset                ; @ $0805 Reset address
  equw endcode              ; @ $0807 Addr of first byte after end of program
  equb "P"
  equs 0,0,0              ; -- Reserved for future use --
  equs "PRT",0            ; @ $080D Short name, max 15 chars - nul terminated
.version_string
  equs "1.0",0              ; Version string - nul terminated

.startprog
.reset
  sei             ; don't interrupt me yet
  cld             ; we don' need no steenkin' BCD
  ldx #$ff        ; set stack pointer to $01FF - only need to set the
  txs             ; LSB, as MSB is assumed to be $01
  stz PRG_EXIT_CODE
  cli

.main
  LOAD_MSG prt_test_msg
  jsr OSPRTMSG
  lda #10
  jsr OSPRTCH
  jsr OSWRMSG
  jsr OSLCDMSG

.prog_end
  jmp OSSFTRST

.prt_test_msg
  equs "ABCDEFGHIJKLMNOPQRSTUVWXZY0123456789$#@_"
  equs "0123456789012345678901234567890123456789",0

.endtag
  equs "EOF",0
.endcode

SAVE "../bin/PRT.BIN", header, endcode
