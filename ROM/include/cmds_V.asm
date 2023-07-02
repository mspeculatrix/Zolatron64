\ ZolOS CLI Commands starting with 'V' - cmds_V.asm

\ ------------------------------------------------------------------------------
\ --- CMD: VERS  :  PRINT FIRMWARE VERSION
\ ------------------------------------------------------------------------------
\ Usage: VERS
\ Print the ZolOS version string to STDOUT and LCD.
.cmdprcVERS
  LOAD_MSG version_str
;  lda #<version_str             ; LSB of message
;  sta MSG_VEC
;  lda #>version_str             ; MSB of message
;  sta MSG_VEC+1
;  jsr duart_println
  jsr OSWRMSG
  jsr OSLCDMSG
  jmp cmdprc_success
