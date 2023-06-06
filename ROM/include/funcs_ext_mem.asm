\ funcs_ext_mem.asm

\ ------------------------------------------------------------------------------
\ ---  EXTMEM_RAM_CHK
\ ------------------------------------------------------------------------------
\ Check whether the currently selected Extended Memory bank is RAM and is
\ available.
\ ON EXIT : - FUNC_ERR = 0 if bank is RAM and is available.
\           - FUNC_ERR = 1 if bank is ROM or Extended ROM-RAM board not fitted.
\ A - O
\ X - O
\ Y - n/a
.extmem_ram_chk
  stz FUNC_ERR            ; Default to 0
  lda EXTMEM_START        ; Load what's currently in first byte of ext memory
  pha                     ; Keep a copy here, to restore later
  ldx #0                  ; We're going to check that we can write to this
.extmem_ram_chk_loop      ; bank. If not, probably a ROM. Write a sequence
  txa                     ; of numbers to EXTMEM_START and read them back
  sta EXTMEM_START        ; Store loop value in memory
  cmp EXTMEM_START        ; Is X the same as what's now stored in this location?
  bne extmem_ram_chk_err
  inx
  cpx #5
  beq extmem_ram_chk_ok
  jmp extmem_ram_chk_loop
.extmem_ram_chk_err
  lda #ERR_EXTMEM_WR
  sta FUNC_ERR
  lda SYS_REG
  and #SYS_EXMEM_NO
  sta SYS_REG
  jmp extmem_ram_chk_done
.extmem_ram_chk_ok
  lda SYS_REG
  ora #SYS_EXMEM
  sta SYS_REG
.extmem_ram_chk_done
  pla                       ; Restore original value of byte, so this process is
  sta EXTMEM_START          ; non-destructive
  rts

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
\ A - O
\ X - n/a
\ Y - n/a
.extmem_readset_bank
  stz FUNC_ERR							              ; Reset
  jsr OSRDINT16                           ; Read a decimal number from STDIN_BUF
  lda FUNC_ERR
  bne extmem_readset_bank_end
  lda FUNC_RES_L
  cmp #16                                 ; Check to see if it's more than 15
  bcs extmem_readset_bank_num_err         ; If it is, error...
  sta EXTMEM_BANK                         ; Store it here for some reason
  sta EXTMEM_SLOT_SEL                     ; Select bank by writing to this addr
  jmp extmem_readset_bank_end
.extmem_readset_bank_num_err
  lda #ERR_EXTMEM_BANK
  sta FUNC_ERR
.extmem_readset_bank_end
  rts

\ --- DATA --------------------
.exmem_fitted_msg
  equs "+ Extended memory",0
.exmem_absent_msg
  ;     01234567890123456789
  equs "- No extended memory",0
