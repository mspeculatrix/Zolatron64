
\ ------------------------------------------------------------------------------
\ ---  EXTMEM_READSET_BANK
\ ------------------------------------------------------------------------------
\ This function reads a decimal number from STDIN_BUF and sets the extended
\ memory bank.
\ ON ENTRY: Expects a number in STDIN_BUF
\ ON EXIT : - Number set in EXTMEM_BANK
\           - Bank selected through latch register
\           - Error in FUNC_ERR
.extmem_readset_bank
  stz FUNC_ERR							              ; Reset
  jsr OSRDINT16                           ; Read a decimal number from STDIN_BUF
  lda FUNC_ERR
  bne extmem_readset_bank_err
  lda FUNC_RES_L
  cmp #15                                 ; Check to see if it's more than 15
  bcs extmem_readset_bank_num_err                  ; If it is, error...
  sta EXTMEM_BANK                         ; Store it for some reason
  sta EXTMEM_SLOT_SEL                     ; Select bank by writing to this addr
  jmp extmem_readset_bank_end
.extmem_readset_bank_num_err
  lda #SYNTAX_ERR_CODE
  sta FUNC_ERR
.extmem_readset_bank_err
  jsr OSWRERR
.extmem_readset_bank_end
  rts
