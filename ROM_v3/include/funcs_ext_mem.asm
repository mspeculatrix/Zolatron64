\ ------------------------------------------------------------------------------
\ ---  EXTMEM_RAM_CHK
\ ------------------------------------------------------------------------------
\ Check whether the currently selected Extended Memory bank is RAM and is
\ available.
\ ON EXIT : - FUNC_ERR = 0 if bank is RAM and is available.
\           - FUNC_ERR = 1 if bank is ROM or Extended ROM-RAM board not fitted.
.extmem_ram_chk
  stz FUNC_ERR            ; Default to 0
  lda EXTMEM_LOC          ; Load what's currently in first byte of ext memory
  sta TMP_VAL             ; Keep a copy here, to restore later
  ldx #0                  ; We're going to check that we can write to this
.extmem_ram_chk_loop      ; bank. If not, it's probably a ROM. We'll write a
  txa                     ; sequence of numbers to EXTMEM_LOC and read them back
  sta EXTMEM_LOC          ; Store loop value in memory
  cmp EXTMEM_LOC          ; Is X the same as what's now stored in this location?
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
  ora #SYS_EXMEM_YES
  sta SYS_REG
.extmem_ram_chk_done
  lda TMP_VAL             ; Restore original value of byte, so this process is
  sta EXTMEM_LOC          ; non-destructive
  rts

\ ------------------------------------------------------------------------------
\ ---  EXTMEM_STAT
\ ------------------------------------------------------------------------------
; Check the SYS_EXTMEM bit in the SYS_REG. This is set on power-up.
; This just tells us if a board is fitted. It doesn't say whether the
; selected bank is ROM or RAM. Need the check above for that.
; ON EXIT : - Carry clear if Ext Mem board fitted.
;           - Carry set if board NOT fitted.
.extmem_stat
  clc
  lda SYS_REG
  and #SYS_EXMEM_YES
  bne extmem_stat_end
  sec
.extmem_stat_end
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
