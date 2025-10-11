\ ZolOS CLI Commands starting with 'H' - cmds_H.asm

\ ------------------------------------------------------------------------------
\ --- CMD: HELP  :  PRINT HELP TEXT
\ ------------------------------------------------------------------------------
\ Usage: HELP
\ Print a list of available commands to STDOUT.
.cmdprcHELP
  ldx #0                    ; Offset for help table
  ldy #0                    ; Count number of chars per command
  stz TMP_VAL               ; Count of how many commands per line
.cmdprcHELP_next_chr
  lda help_table,X
  beq cmdprcHELP_padcmd     ; If 0, at end of command name, so pad with 0s
  cmp #EOTBL_MKR            ; Or are we at the end of the table?
  beq cmdprcHELP_end
  jsr OSWRCH                ; If neither of above, write character
  inx                       ; Increment help table offset, for next char
  iny                       ; Increment number of characters we've printed
  jmp cmdprcHELP_next_chr
.cmdprcHELP_padcmd
  lda TMP_VAL               ; Check if we've done max cmds per line
  cmp #CMDS_PER_LINE        ; CMDS_PER_LINE defined in cfg_ROM.asm
  beq cmdprcHELP_nextline   ; If we've reached the max, let's start a new line
  inc TMP_VAL               ; Otherwise, just increment how many cmds this line
.cmdprcHELP_addspc
  cpy #CMD_MAX_LEN          ; Y contains num of chars we've printed
  beq cmdprcHELP_cmddone    ; If we're at that number, we're done
  lda #' '                  ; Otherwise, print a space
  jsr OSWRCH
  iny                       ; Increase Y and
  jmp cmdprcHELP_addspc     ; go around again
.cmdprcHELP_cmddone
  ldy #0                    ; Reset character count for next command
  inx                       ; Increase count of how many commands printed
  jmp cmdprcHELP_next_chr   ; Go around for next char in table
.cmdprcHELP_nextline
  ldy #0                    ; Reset character count for next command
  inx                       ; Increase count of how many commands printed
  stz TMP_VAL               ; Reset how many commands printed this line
  lda #CHR_LINEEND          ; Print a line feed
  jsr OSWRCH
  jmp cmdprcHELP_next_chr   ; Go get the next char from the table
.cmdprcHELP_end
  jmp cmdprc_success
