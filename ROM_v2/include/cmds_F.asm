\ ------------------------------------------------------------------------------
\ --- CMD: FLOAD  :  LOAD INTO FLASH MEMORY
\ ------------------------------------------------------------------------------
.cmdprcFLOAD
  ; retrieve a decimal number from STDIN_BUF. Check it's in the range 0-15.
  ; Do this in a way that it can also be called from user software, so that
  ; user software can load additional modules into Flash memory.
  ; Here, we're dealing with user input in the OS. But the actual load
  ; routine should be implemented as an OS call. We can, for example, load
  ; the number for the memory bank into FUNC_PARAM.
  jmp cmdprc_end

.cmdprcFLOAD_fail
  jmp cmdprc_fail

\ ------------------------------------------------------------------------------
\ --- CMD: FLIST  :  LIST PROGRAMS IN FLASH MEMORY
\ ------------------------------------------------------------------------------
\ List the programs in Flash memory. This assumes that the programs comply with
\ the protocol of having a nul-terminated name string at $080D.
.cmdprcFLIST
  ldy #0                          ; Number of bank
.cmdprcFLIST_loop
  sty FL_SLOT_SEL                 ; Select the Flash memory slot
  ldx #0                          ; Offset for chars in name
  cpy #10                         ; See if we need a leading space
  bcs cmdprcFLIST_print_idx       ; If not, skip ahead
  lda #' '                        ; Print a space
  jsr OSWRCH
.cmdprcFLIST_print_idx
  tya                             ; Put the bank number into A, convert it to
  jsr OSB2ISTR                    ; an integer string and then print it.
  jsr OSWRSBUF
  lda #' '                        ; Followed by a space
  jsr OSWRCH
  lda FLASHMEM_LOC                ; Load the first byte of the code and compare
  cmp #$4C                        ; to JMP instruction - if not this then prob
  bne cmdprcFLIST_name_loop_done  ; no program loaded in this bank.
.cmdprcFLIST_name_loop
  lda FLASHMEM_LOC+$0D,X          ; Filename starts at $0D offset from start of
  beq cmdprcFLIST_name_loop_done  ; code. If char is 0, we're done
  jsr OSWRCH
  inx                             ; Increment for next char
  cmp #ZD_MAX_FN_LEN              ; Have we already printed a filename's worth?
  beq cmdprcFLIST_name_loop_done  ; If so, we've gone too far
  jmp cmdprcFLIST_name_loop       ; Otherwise, get another char
.cmdprcFLIST_name_loop_done
  lda #CHR_LINEEND                ; Print a linefeed at the end of this entry
  jsr OSWRCH
  iny                             ; Increment to next bank
  cpy #16
  beq cmdprcFLIST_done
  jmp cmdprcFLIST_loop
.cmdprcFLIST_done
  jmp cmdprc_end


\ ------------------------------------------------------------------------------
\ --- CMD: FSEL  :  SELECT FLASH MEMORY BANK
\ ------------------------------------------------------------------------------
.cmdprcFRUN
  stz STDIN_BUF
  stz STDIN_IDX
  stz PRG_EXIT_CODE             ; Reset Program Exit Code
  jmp FLASHMEM_LOC

\ ------------------------------------------------------------------------------
\ --- CMD: FSEL  :  SELECT FLASH MEMORY BANK
\ ------------------------------------------------------------------------------
.cmdprcFS
  jsr OSRDINT16                           ; Read a decimal number from STDIN_BUF
  lda FUNC_ERR
  bne cmdprcFS_err
  lda FUNC_RES_L
  cmp #15                                 ; Check to see if it's more than 15
  bcs cmdprcFS_num_err                    ; If it is, error...
  sta FLASH_BANK                          ; Store it for some reason
  sta FL_SLOT_SEL                         ; Select bank by writing to this addr
  jmp cmdprcFS_end
.cmdprcFS_num_err
  lda #SYNTAX_ERR_CODE
  sta FUNC_ERR
.cmdprcFS_err
  jsr OSWRERR
.cmdprcFS_end
  jmp cmdprc_end

  