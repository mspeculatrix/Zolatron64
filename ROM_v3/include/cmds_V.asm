\ ------------------------------------------------------------------------------
\ --- CMD: VERS  :  PRINT FIRMWARE VERSION
\ ------------------------------------------------------------------------------
.cmdprcVERS
  lda #<version_str             ; LSB of message
  sta MSG_VEC
  lda #>version_str             ; MSB of message
  sta MSG_VEC+1
  jsr duart_println
  jsr OSLCDMSG
  jmp cmdprc_end
