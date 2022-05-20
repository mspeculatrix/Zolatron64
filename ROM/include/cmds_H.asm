\ ------------------------------------------------------------------------------
\ --- CMD: HELP
\ ------------------------------------------------------------------------------
.cmdprcHELP
  ldx #0                    ; Offset for help table
  ldy #0                    ; Count number of chars per command
  stz TMP_VAL               ; Count of how many commands per line
.cmdprcHELP_next_chr
  lda help_table,X
  beq cmdprcHELP_padcmd     ; If 0, at end of command, so pad with 0s
  cmp #EOTBL_MKR            ; Or are we at the end of the table?
  beq cmdprcHELP_end
  jsr OSWRCH                ; If neither of above, write character
  inx
  iny
  jmp cmdprcHELP_next_chr
.cmdprcHELP_padcmd
  lda TMP_VAL               ; Check if we've done max cmds per line
  cmp #6
  beq cmdprcHELP_nextline
  inc TMP_VAL
.cmdprcHELP_addspc
  cpy #8
  beq cmdprcHELP_cmddone
  lda #' '
  jsr OSWRCH
  iny
  jmp cmdprcHELP_addspc
.cmdprcHELP_cmddone
  ldy #0
  inx
  jmp cmdprcHELP_next_chr
.cmdprcHELP_nextline
  ldy #0
  inx
  stz TMP_VAL
  lda #CHR_LINEEND
  jsr OSWRCH
  jmp cmdprcHELP_next_chr
.cmdprcHELP_end
  lda #CHR_LINEEND
  jsr OSWRCH
  jmp cmdprc_end
