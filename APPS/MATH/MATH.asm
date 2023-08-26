; Code for Zolatron 64 6502-based microcomputer.
;
; GitHub: https://github.com/mspeculatrix/Zolatron64/
; Blog: https://mansfield-devine.com/speculatrix/category/projects/zolatron/
;
; Written for the Beebasm assembler
; Assemble with:
; beebasm -v -i MATH.asm

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

; -- OPTIONAL --
; INCLUDE "../../LIB/cfg_parallel.asm"
; INCLUDE "../../LIB/cfg_prt.asm"
; INCLUDE "../../LIB/cfg_user_port.asm"
; INCLUDE "../../LIB/cfg_ZolaDOS.asm"
; INCLUDE "../../LIB/cfg_chk_char.asm"

; INCLUDE "../../LIB/cfg_rtc_ds3234.asm"
; INCLUDE "../../LIB/funcs_rtc_ds3234.asm"
; INCLUDE "../../LIB/cfg_spi65.asm"
; INCLUDE "../../LIB/funcs_spi65.asm"

UINT8        = $5000

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
  equs "MATH",0   		      ; @ $080D Short name, max 15 chars - nul terminated
.version_string
  equs "1.0",0              ; Version string - nul terminated

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

.main

;  lda #$23
;  sta MATH_TMP_A

  ; Multiply 0x0000FA55 x 0x0000EE33
  ; Store numbers in little-endian format
;  lda #$55
;  sta UINT32_A + 3
;  lda #$FA
;  sta UINT32_A + 2
;  stz UINT32_A + 1
;  stz UINT32_A

;  lda #$33
;  sta UINT32_B + 3
;  lda #$EE
;  sta UINT32_B + 2
;  stz UINT32_B + 1
;  stz UINT32_B

  jsr clear_res_reg

;  jsr show_registers

;  lda #':'
;  jsr OSWRCH
;  lda #10
;  jsr OSWRCH

;  jsr uint32_mult32
;  jsr show_registers

;  jsr clear_res_reg
;  jsr show_registers

;  jsr uint32_mult8
;  jsr show_registers

  jsr clear_registers

  \ DIVIDE 32-bit int by 16-bit int
  \ We'll divide 0x23456789 by 0x9876
  lda #$63
  sta UINT32_A
  lda #$C9
  sta UINT32_A + 1
  lda #$8B
  sta UINT32_A + 2
  lda #$25
  sta UINT32_A + 3

  lda #$76
  sta UINT16_B
  lda #$23
  sta UINT16_B + 1

  jsr show_registers
  lda #10
  jsr OSWRCH

  jsr uint32_div16

  jsr show_registers

  lda #10
  jsr OSWRCH
  lda #10
  jsr OSWRCH

  jsr clear_registers

  lda #$63
  sta UINT32_A
  lda #$C9
  sta UINT32_A + 1
  lda #$8B
  sta UINT32_A + 2
  lda #$25
  sta UINT32_A + 3

  lda #$76
  sta MATH_TMP_A

  jsr show_registers


  jsr uint32_div8

  jsr show_registers


;  LOAD_MSG result_msg
;  jsr OSWRMSG

  jmp prog_end

\ ***** FUNCTIONS *****

.clear_registers
  ldx #3
.clear_reg_loop
  stz UINT32_A,X
  stz UINT32_B,X
  stz UINT32_RES,X
  dex
  bpl clear_reg_loop
  rts

.clear_res_reg
  ldx #7
.clear_res_reg_loop
  stz UINT32_RES64,X
  dex
  bpl clear_res_reg_loop
  rts

.show_registers
;  lda #'8'
;  jsr OSWRCH
;  lda #' '
;  jsr OSWRCH
;  lda UINT8
;  jsr OSB2HEX   ; result in STR_BUF
;  jsr OSWRSBUF
;  lda #10
;  jsr OSWRCH

  lda #'A'
  jsr OSWRCH
  lda #' '
  jsr OSWRCH
  ldx #3
.show_reg_loop_A
  lda UINT32_A, X
  jsr OSB2HEX   ; result in STR_BUF
  jsr OSWRSBUF
  lda #' '
  jsr OSWRCH
  dex
  bpl show_reg_loop_A
  lda #10
  jsr OSWRCH

  lda #'D'
  jsr OSWRCH
  lda #' '
  jsr OSWRCH
  ldx #1
.show_reg_loop_D
  lda UINT16_B, X
  jsr OSB2HEX   ; result in STR_BUF
  jsr OSWRSBUF
  lda #' '
  jsr OSWRCH
  dex
  bpl show_reg_loop_D
  lda #10
  jsr OSWRCH
;  lda #'B'
;  jsr OSWRCH
;  lda #' '
;  jsr OSWRCH
;  ldx #3
;.show_reg_loop_B
;  lda UINT32_B, X
;  jsr OSB2HEX   ; result in STR_BUF
;  jsr OSWRSBUF
;  lda #' '
;  jsr OSWRCH
;  dex
;  bpl show_reg_loop_B
;  lda #10
;  jsr OSWRCH

;  lda #'R'
;  jsr OSWRCH
;  lda #' '
;  jsr OSWRCH
;  ldx #7
;.show_reg_loop_R
;  lda UINT32_RES64, X
;  jsr OSB2HEX   ; result in STR_BUF
;  jsr OSWRSBUF
;  lda #' '
;  jsr OSWRCH
;  dex
;  bpl show_reg_loop_R
;  lda #10
;  jsr OSWRCH

; lda #'Q'
;  jsr OSWRCH
;  lda #' '
;  jsr OSWRCH
;  ldx #3
;.show_reg_loop_Q
;  lda UINT32_RES_Q, X
;  jsr OSB2HEX   ; result in STR_BUF
;  jsr OSWRSBUF
;  lda #' '
;  jsr OSWRCH
;  dex
;  bpl show_reg_loop_Q
;  lda #10
;  jsr OSWRCH

 lda #'R'
  jsr OSWRCH
  lda #' '
  jsr OSWRCH
  ldx #3
.show_reg_loop_M
  lda UINT32_RES, X
  jsr OSB2HEX   ; result in STR_BUF
  jsr OSWRSBUF
  lda #' '
  jsr OSWRCH
  dex
  bpl show_reg_loop_M
  lda #10
  jsr OSWRCH



  rts


.prog_end
  jmp OSSFTRST


INCLUDE "../../LIB/math_uint8_mult.asm"
INCLUDE "../../LIB/math_uint32_mult8.asm"
INCLUDE "../../LIB/math_uint32_mult32.asm"
INCLUDE "../../LIB/math_uint32_div16.asm"
INCLUDE "../../LIB/math_uint32_div8.asm"

.result_msg
  equs "Quotient : 0x10F0D",10
  equs "Remainder: 0x1265",10,0

.endtag
  equs "EOF",0
.endcode

SAVE "../bin/MATH.EXE", header, endcode
