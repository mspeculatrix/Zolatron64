
\ ------------------------------------------------------------------------------
\ ---  EXTMEM_READSET_BANK
\ ------------------------------------------------------------------------------
\ This function reads a decimal number from STDIN_BUF and sets the extended
\ memory bank.
\ ON ENTRY: - Expects a number in STDIN_BUF
\           - Assumes STDIN_IDX points to the bank number in STDIN_BUF
\ ON EXIT : - Bank number set in EXTMEM_BANK
\           - Bank selected through latch register
\           - Error in FUNC_ERR
.extmem_readset_bank
  stz FUNC_ERR							              ; Reset
  jsr OSRDINT16                           ; Read a decimal number from STDIN_BUF
  lda FUNC_ERR
  bne extmem_readset_bank_end
  lda FUNC_RES_L
  cmp #16                                 ; Check to see if it's more than 15
  bcs extmem_readset_bank_num_err         ; If it is, error...
  sta EXTMEM_BANK                         ; Store it for some reason
  sta EXTMEM_SLOT_SEL                     ; Select bank by writing to this addr
  jmp extmem_readset_bank_end
.extmem_readset_bank_num_err
  lda #ERR_EXTMEM_BANK
  sta FUNC_ERR
.extmem_readset_bank_end
  rts
