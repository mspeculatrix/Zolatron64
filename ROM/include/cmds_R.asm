\ ZolOS CLI Commands starting with 'R' - cmds_R.asm

\ ------------------------------------------------------------------------------
\ --- CMD: RUN  :  RUN PROGRAM
\ ------------------------------------------------------------------------------
\ Usage: RUN
\ Execute a program loaded at the standard user program location, USR_START
.cmdprcRUN
  jsr check_exec                ; Check if executable program loaded
  lda FUNC_ERR
  bne cmdprcRUN_err             ; An error suggests not
  stz STDIN_BUF                 ; Otherwise, clean up a few things
  stz STDIN_IDX                 ; Reset RX buffer index
  stz PRG_EXIT_CODE             ; Reset Program Exit Code
  jmp USR_START
.cmdprcRUN_err
  jmp cmdprc_fail

.check_exec
  stz FUNC_ERR
  lda USR_START
  cmp #$4C                      ; Executables start with a JMP command
  bne cmdprocRUN_err
  lda USR_START + CODEHDR_TYPE  ; Executables should also have an 'E' type
  cmp #TYPECODE_EXEC            ; code
  bne cmdprocRUN_err
  jmp cmdprocRUN_end
.cmdprocRUN_err
  lda #ERR_NO_EXECUTABLE
  sta FUNC_ERR
.cmdprocRUN_end
  rts
