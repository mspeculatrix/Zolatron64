\ ------------------------------------------------------------------------------
\ --- CMD: XLOAD  :  LOAD CODE INTO EXTENDED RAM
\ ------------------------------------------------------------------------------
\ Usage: XLOAD <filename> <memory_bank>
\ The memory_bank must be in the range 0-15.
.cmdprcXLOAD
  jsr read_filename       ; Read filename from STDIN_BUF
  lda FUNC_ERR
  bne cmdprcXLOAD_err
  jsr extmem_readset_bank ; Read memory bank number. Bank will be selected.
  lda FUNC_ERR
  bne cmdprcXLOAD_err
  ldx #0                  ; We're going to check that we can write to this
.cmdprcXLOAD_bank_chk     ; bank. If not, it's probably a ROM. We'll write
  txa                     ; a sequence of numbers to $8000 and read them back.
  sta $8000               ; Store in memory
  cmp $8000               ; Is X the same as what's now stored in this location?
  bne cmdprcXLOAD_bank_chk_err
  inx
  cpx #5
  beq cmdprcXLOAD_loadfile
  jmp cmdprcXLOAD_bank_chk
.cmdprcXLOAD_bank_chk_err
  lda #ERR_EXTMEM_WR
  sta FUNC_ERR
  jmp cmdprcXLOAD_err
.cmdprcXLOAD_loadfile     ; Here's where we actually load the file
  LED_ON LED_FILE_ACT
  lda #<EXTMEM_LOC        ; This is where we're going to load the code
  sta FILE_ADDR
  lda #>EXTMEM_LOC
  sta FILE_ADDR+1
  jsr OSZDLOAD
  lda FUNC_ERR
  bne cmdprcXLOAD_err
  LOAD_MSG file_act_complete_msg
  jsr OSWRMSG
  jsr OSLCDMSG
  jmp cmdprcXLOAD_done
.cmdprcXLOAD_err
  jsr OSWRERR          ; There should be an error code in FUNC_ERR
  jsr OSLCDERR  
.cmdprcXLOAD_done
  LED_OFF LED_FILE_ACT
  jmp cmdprc_end

\ ------------------------------------------------------------------------------
\ --- CMD: XLIST  :  LIST PROGRAMS IN EXTENDED MEMORY
\ ------------------------------------------------------------------------------
\ List the programs in extended memory. This assumes that the programs comply 
\ with the protocol of having a nul-terminated name string at $080D.
.cmdprcXLIST
  ldy #0                          ; Number of bank
.cmdprcXLIST_loop
  sty EXTMEM_SLOT_SEL             ; Select the ext memory slot
  cpy #10                         ; See if we need a leading space
  bcs cmdprcXLIST_print_idx       ; If not, skip ahead
  lda #' '                        ; Print a space
  jsr OSWRCH
.cmdprcXLIST_print_idx
  tya                             ; Put the bank number into A, convert it to
  jsr OSB2ISTR                    ; an integer string and then print it.
  jsr OSWRSBUF
  lda #' '                        ; Followed by a space
  jsr OSWRCH
  lda EXTMEM_LOC                  ; Load the first byte of the code and compare
  cmp #$4C                        ; to JMP instruction - if not this then prob
  bne cmdprcXLIST_name_loop_done  ; no program loaded in this bank.
  lda EXTMEM_LOC+8                ; Load the data type code
  sta TEST_VAL
  beq cmdprcXLIST_name_loop_done  ; If a zero, nothing more to do
  ldx #0                          ; Index for loop
.cmdprcXLIST_dtype_loop
  lda ext_data_types,X
  beq cmdprcXLIST_name_loop_done  ; If zero, run out of options. Not valid
  cmp TEST_VAL                    ; Same as our code?
  beq cmdprcXLIST_dtype_prt       ; If so, print it
  inx                             ; Otherwise, try again
  jmp cmdprcXLIST_dtype_loop
.cmdprcXLIST_dtype_prt
  lda #' '                        ; Followed by a space
  jsr OSWRCH
  lda TEST_VAL
  jsr OSWRCH
  lda #' '                        ; Followed by a space
  jsr OSWRCH
.cmdprcXLIST_name
  ldx #0                          ; Offset for chars in name
.cmdprcXLIST_name_loop
  lda EXTMEM_LOC+$0D,X            ; Filename starts at $0D offset from start of
  beq cmdprcXLIST_name_loop_done  ; code. If char is 0, we're done
  jsr OSWRCH
  inx                             ; Increment for next char
  cmp #ZD_MAX_FN_LEN              ; Have we already printed a filename's worth?
  beq cmdprcXLIST_name_loop_done  ; If so, we've gone too far
  jmp cmdprcXLIST_name_loop       ; Otherwise, get another char
.cmdprcXLIST_name_loop_done
  lda #CHR_LINEEND                ; Print a linefeed at the end of this entry
  jsr OSWRCH
  iny                             ; Increment to next bank
  cpy #16
  beq cmdprcXLIST_done
  jmp cmdprcXLIST_loop
.cmdprcXLIST_done
  jmp cmdprc_end

\ ------------------------------------------------------------------------------
\ --- CMD: XRUN  :  RUN PROGRAM IN CURRENT EXTENDED MEMORY BANK
\ ------------------------------------------------------------------------------
.cmdprcXRUN
  stz STDIN_BUF
  stz STDIN_IDX
  stz PRG_EXIT_CODE                       ; Reset Program Exit Code
  jmp EXTMEM_LOC

\ ------------------------------------------------------------------------------
\ --- CMD: XSEL  :  SELECT EXTENDED MEMORY BANK
\ ------------------------------------------------------------------------------
\ Usage: XSEL <0-15>
.cmdprcXSEL
  jsr extmem_readset_bank
  lda FUNC_ERR
  beq cmdprcXSEL_end
  jsr OSWRERR
.cmdprcXSEL_end
  jmp cmdprc_end
