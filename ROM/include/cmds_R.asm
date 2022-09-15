\ cmds_R.asm

\ ------------------------------------------------------------------------------
\ --- CMD: RUN  :  RUN PROGRAM
\ ------------------------------------------------------------------------------
\ Usage: RUN
\ Execute a program loaded at the standard user program location, USR_START
.cmdprcRUN
;  lda USR_START
;  cmp #$4C                      ; Executables start with a JMP command
;  bne cmdprcRUN_err
;  lda USR_START + CODEHDR_TYPE  ; Executables should also have an 'E' type
;  cmp #TYPECODE_EXEC            ; code
;  bne cmdprcRUN_err
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
  bne check_exec_err
  lda USR_START + CODEHDR_TYPE  ; Executables should also have an 'E' type
  cmp #TYPECODE_EXEC            ; code
  bne check_exec_err
  jmp check_exec_end
.check_exec_err
  lda #ERR_NO_EXECUTABLE
  sta FUNC_ERR
.check_exec_end
  rts
