; Code for Zolatron 64 6502-based microcomputer.
;

; Test program that reads from a PS/2 keyboard attached to User Port A.

; GitHub: https://github.com/mspeculatrix/Zolatron64/
; Blog: https://mansfield-devine.com/speculatrix/category/projects/zolatron/
;
; Written for the Beebasm assembler
; Assemble with:
; beebasm -v -i <filename>.asm

CPU 1                               ; use 65C02 instruction set

INCLUDE "../../LIB/cfg_main.asm"
INCLUDE "../../LIB/cfg_page_0.asm"    ; System ero page addresses
; PAGE 1 is the STACK
INCLUDE "../../LIB/cfg_page_2.asm"    ; OS Indirection Table
; PAGE 3 is used for STDIN & STDOUT buffers, plus indexes
INCLUDE "../../LIB/cfg_page_4.asm"    ; Misc buffers etc
; PAGE 5 is available for user code workspace
; PAGE 6 - ZolaDOS workspace
INCLUDE "../../LIB/cfg_page_7.asm"    ; SPI, RTC, SD addresses etc

\ ------------------------------------------------------------------------------
\ ---  OPTIONAL LIBRARY CONFIG FILES
\ ------------------------------------------------------------------------------
INCLUDE "../../LIB/cfg_user_port.asm"

ORG USR_START
.header                     ; HEADER INFO
  jmp startprog             ; $4C followed by 2-byte address
  equb "E"                  ; @ $0803 E=executable, D=data, O=overlay, X=OS ext
  equb <header              ; @ $0804 Entry address
  equb >header
  equb <reset               ; @ $0806 Reset address
  equb >reset
  equb <endcode             ; @ $0808 Addr of first byte after end of program
  equb >endcode
  equs 0,0,0                ; -- Reserved for future use --
.prog_name
  equs "KEYB",0         ; @ $080D Short name, max 15 chars - null terminated
.version_string
  equs "1.0",0              ; Version string - null terminated

.startprog                  ; Start of main program code
.reset                      ; May sometimes be different from startprog
  sei                       ; Turn off interrupts
  cld                       ; Turn off BCD
  ldx #$ff                  ; Set stack pointer to $01FF - only need to set the
  txs                       ; LSB, as MSB is assumed to be $01

  stz PRG_EXIT_CODE         ; Should have an OS routine for initialising progs?
  stz FUNC_ERR
  stz FUNC_RESULT
  cli

\ ------------------------------------------------------------------------------
\ ---  MAIN PROGRAM
\ ------------------------------------------------------------------------------
.main
;  stz USRP_DDRA             ; Set User Port A as all inputs
;  lda USRP_IER              ; Load Interrupt Enable Register
;  ora #%10000010            ; Enable interrupts for CA1
;  sta USRP_IER

;  lda USRP_PCR              ; Ensure bit 1 unset to have CA1 cause interrupt on
;  and #%11111110            ; falling edge
;  sta USRP_PCR

  ; Should the stuff above be part of keyb_setup???

  jsr keyb_setup

  LOAD_MSG start_msg
  jsr OSWRMSG

.main_loop
  jsr keyb_poll
;  beq main_loop   ; If zero, no user port interrupt was set
  bcc main_loop
  jsr OSWRCH      ; If not zero, we got a character, so print it

  jmp main_loop

.prog_end
  jmp OSSFTRST

\ ------------------------------------------------------------------------------
\ ---  FUNCTIONS
\ ------------------------------------------------------------------------------

\ ------------------------------------------------------------------------------
\ ---  DATA
\ ------------------------------------------------------------------------------

.start_msg
  equs "Waiting for keyboard input...",10,0

\ ------------------------------------------------------------------------------
\ ---  OPTIONAL LIBRARY FUNCTION FILES
\ ------------------------------------------------------------------------------
INCLUDE "../../LIB/funcs_keyb.asm"

.endtag
  equs "EOF",0
.endcode

SAVE "../bin/KEYB.EXE", header, endcode
