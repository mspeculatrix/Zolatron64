; Code for Zolatron 64 6502-based microcomputer.
;
; GitHub: https://github.com/mspeculatrix/Zolatron64/
; Blog: https://mansfield-devine.com/speculatrix/category/projects/zolatron/
;
; Written for the Beebasm assembler
; Assemble with:
; beebasm -v -i ADV.asm

CPU 1                               ; use 65C02 instruction set

INCLUDE "../../LIB/cfg_main.asm"
INCLUDE "../../LIB/cfg_page_0.asm"
; PAGE 1 is the STACK
INCLUDE "../../LIB/cfg_page_2.asm"
; PAGE 3 is used for STDIN & STDOUT buffers, plus indexes
INCLUDE "../../LIB/cfg_page_4.asm"
INCLUDE "../../LIB/cfg_VIAC.asm"

MACRO NEWLINE
  lda #CHR_LINEEND
  jsr OSWRCH
ENDMACRO

ORG USR_PAGE
.startcode
  sei             ; don't interrupt me yet
  cld             ; we don' need no steenkin' BCD
  ldx #$ff        ; set stack pointer to $01FF - only need to set the
  txs             ; LSB, as MSB is assumed to be $01

  lda #0
  sta PRG_EXIT_CODE
  cli

  stz VIAC_PORTA
  stz VIAC_PORTB

.main

  LOAD_MSG start_msg
  jsr OSWRMSG
  NEWLINE
  NEWLINE

  LOAD_MSG location_00
  jsr OSWRMSG

.prog_end
  jmp OSSFTRST

.start_msg
  equs "Adventure", 10, 10
  equs "<--- Your terminal must be at least this wide to go on this ride --->",0

.location_00
  equs "You find yourself standing in a large, open-plan office.",10
  equs "You're the only one here.",10
  equs "It's night and the office is dimly lit by a few glowing computer",10
  equs "screens, blinking router LEDs and the occasional anglepoise.",10
  equs "Above the hum of the A/C and the faint sound of traffic outside you",10
  equs "can hear a feeble electronic beeping. But it's not obvious where",10
  equs "it's coming from.",10
  equs "Nearby, one desk supports a bizarrely old-fashioned terminal. Its",10
  equs "CRT display shows a message in green characters that you find",10
  equs "strangely comforting.",0

.endcode

SAVE "../bin/ADV.BIN", startcode, endcode
