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
INCLUDE "../../LIB/cfg_ZolaDOS.asm"
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
  equs "XLS",0           ; @ $080D Short name, max 15 chars - nul terminated
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

\ ------------------------------------------------------------------------------


  ldy #0                           ; Number of memory bank
.cmdprcXLS_loop

  jsr cmdprcXLS_prt_item
  phy

  ldx #3
.cmdprcXLS_loop_inner
  tya
  clc
  adc #4
  tay
  jsr cmdprcXLS_prt_item
  dex
  bne cmdprcXLS_loop_inner


  ply
  iny                             ; Increment to next bank
  lda #CHR_LINEEND                ; Print a linefeed at the end of this entry
  jsr OSWRCH
  cpy #4
  beq cmdprcXLS_done
  jmp cmdprcXLS_loop
.cmdprcXLS_done
  lda EXTMEM_BANK                 ; Restore the currently selected bank
  sta EXTMEM_SLOT_SEL

.prog_end
  jmp OSSFTRST



.cmdprcXLS_prt_item                ; Bank number is in Y
  phx
  sty EXTMEM_SLOT_SEL              ; Select the ext memory slot
  cpy #10                          ; See if we need a leading space
  bcs cmdprcXLS_print_idx          ; If not, skip ahead
  lda #' '                         ; Print a space
  jsr OSWRCH
.cmdprcXLS_print_idx
  tya                              ; Put the bank number into A, convert it to
  jsr OSB2ISTR                     ; an integer string and then print it.
  jsr OSWRSBUF
  lda #' '                         ; Followed by a space
  jsr OSWRCH
  cpy EXTMEM_BANK                  ; Is this the currently selected bank?
  beq cmdprcXLS_currbank_is
  lda #' '
  jmp cmdprcXLS_currbank_done
.cmdprcXLS_currbank_is
  lda #'*'
.cmdprcXLS_currbank_done
  jsr OSWRCH
  lda EXTMEM_START + CODEHDR_TYPE  ; Load the data type code
  sta TEST_VAL
  ldx #0                           ; Index for loop
.cmdprcXLS_dtype_loop
  lda ext_data_types,X
  beq cmdprcXLS_no_type            ; If zero, run out of options
  cmp TEST_VAL                     ; Same as our code?
  beq cmdprcXLS_dtype_prt          ; If so, print it
  inx                              ; Otherwise, try again
  jmp cmdprcXLS_dtype_loop
.cmdprcXLS_dtype_prt
  lda TEST_VAL
  jsr OSWRCH
  jmp cmdprcXLS_main
.cmdprcXLS_no_type
  stz TEST_VAL
  lda #' '                         ; Followed by a space
  jsr OSWRCH
.cmdprcXLS_main
  lda #' '
  jsr OSWRCH
  lda TEST_VAL
  beq cmdprcXLS_blank
  cmp #TYPECODE_DATA
  beq cmdprcXLS_data_label
  cmp #TYPECODE_OVLY
  beq cmdprcXLS_overlay_label
  jmp cmdprcXLS_name
.cmdprcXLS_blank
  ldx #0
.cmdprcXLS_blank_loop
  lda #' '
  jsr OSWRCH
  cpx #ZD_MAX_FN_LEN
  beq cmdprcXLS_name_loop_done
  inx
  jmp cmdprcXLS_blank_loop
.cmdprcXLS_name
  ldx #0                          ; Offset for chars in name
.cmdprcXLS_name_loop
  lda EXTMEM_START+CODEHDR_NAME,X ; Filename starts at $0D offset from start of
  beq cmdprcXLS_name_pad    ; code. If char is 0, we're done
  jsr OSWRCH
  inx                             ; Increment for next char
  cpx #ZD_MAX_FN_LEN              ; Have we already printed a filename's worth?
  beq cmdprcXLS_name_loop_done    ; If so, we've gone far enough
  jmp cmdprcXLS_name_loop         ; Otherwise, get another char
.cmdprcXLS_name_pad
  lda #' '
  jsr OSWRCH
  cpx #ZD_MAX_FN_LEN              ; Have we already printed a filename's worth?
  beq cmdprcXLS_name_loop_done
  inx
  jmp cmdprcXLS_name_pad
.cmdprcXLS_data_label
  LOAD_MSG xls2_data_label
  jsr OSWRMSG
  jmp cmdprcXLS_name_loop_done
.cmdprcXLS_overlay_label
  LOAD_MSG cmdprcXLS_overlay_label
  jsr OSWRMSG
.cmdprcXLS_name_loop_done
  lda #' '
  jsr OSWRCH
  plx
  rts

\ --- DATA ----------------
.bank_select_msg
  equs "Bank selected: ",0

.xls2_data_label
  equs "-- data -----",0

.ext_data_types               ; Valid data type characters for extended memory
  equs "BDEOX",0
\ ------------------------------------------------------------------------------
.endtag
  equs "EOF",0
.endcode

SAVE "../bin/XLS.EXE", header, endcode
