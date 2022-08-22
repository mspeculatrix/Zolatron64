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
.cmdprcFSEL
  jsr OSRDINT16                           ; Read a decimal number from STDIN_BUF
  lda FUNC_ERR
  bne cmdprcFSEL_err
  lda FUNC_RES_L
  cmp #15                                 ; Check to see if it's more than 15
  bcs cmdprcFSEL_num_err                  ; If it is, error...
  sta FLASH_BANK                          ; Store it for some reason
  sta FL_SLOT_SEL                         ; Select bank by writing to this addr
  jmp cmdprcFSEL_end
.cmdprcFSEL_num_err
  lda #SYNTAX_ERR_CODE
  sta FUNC_ERR
.cmdprcFSEL_err
  jsr OSWRERR
.cmdprcFSEL_end
  jmp cmdprc_end

  