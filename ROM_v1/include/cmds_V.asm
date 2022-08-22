\ ------------------------------------------------------------------------------
\ --- CMD: VERS  :  PRINT FIRMWARE VERSION
\ ------------------------------------------------------------------------------
.cmdprcVERS
  lda #<version_str             ; LSB of message
  sta MSG_VEC
  lda #>version_str             ; MSB of message
  sta MSG_VEC+1
  jsr acia_println
  jmp cmdprc_end
