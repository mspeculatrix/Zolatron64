\ cmds_X.asm

\ ------------------------------------------------------------------------------
\ --- CMD: XLS  :  LIST PROGRAMS IN EXTENDED MEMORY
\ ------------------------------------------------------------------------------
\ Usage: XLS
\ List the programs in extended memory. This assumes that the programs comply
\ with the protocol of having a nul-terminated name string at $080D.
.cmdprcXLS
  LED_ON LED_FILE_ACT
  ldy #0                          ; Number of memory bank
.cmdprcXLS_loop
  sty EXTMEM_SLOT_SEL             ; Select the ext memory slot
  cpy #10                         ; See if we need a leading space
  bcs cmdprcXLS_print_idx       ; If not, skip ahead
  lda #' '                        ; Print a space
  jsr OSWRCH
.cmdprcXLS_print_idx
  tya                             ; Put the bank number into A, convert it to
  jsr OSB2ISTR                    ; an integer string and then print it.
  jsr OSWRSBUF
  lda #' '                        ; Followed by a space
  jsr OSWRCH
  cpy EXTMEM_BANK                 ; Is this the currently selected bank?
  beq cmdprcXLS_currbank_is
  lda #' '
  jmp cmdprcXLS_currbank_done
.cmdprcXLS_currbank_is
  lda #'*'
.cmdprcXLS_currbank_done
  jsr OSWRCH
;  lda EXTMEM_START                ; Load the first byte of the code and compare
;  cmp #$4C                        ; to JMP instruction - if not this then no
;  bne cmdprcXLS_name_loop_done    ; executable/named code loaded in this bank
  lda EXTMEM_START + CODEHDR_TYPE  ; Load the data type code
  sta TEST_VAL
  beq cmdprcXLS_name_loop_done     ; If a zero, nothing more to do
  ldx #0                           ; Index for loop
.cmdprcXLS_dtype_loop
  lda ext_data_types,X
  beq cmdprcXLS_name_loop_done     ; If zero, run out of options. Not valid
  cmp TEST_VAL                     ; Same as our code?
  beq cmdprcXLS_dtype_prt          ; If so, print it
  inx                              ; Otherwise, try again
  jmp cmdprcXLS_dtype_loop
.cmdprcXLS_dtype_prt
  lda TEST_VAL
  jsr OSWRCH
  lda #' '                         ; Followed by a space
  jsr OSWRCH
  lda TEST_VAL
  cmp #TYPECODE_DATA
  beq cmdprcXLS_data_label
  cmp #TYPECODE_OVLY
  beq cmdprcXLS_overlay_label
.cmdprcXLS_name
  ldx #0                          ; Offset for chars in name
.cmdprcXLS_name_loop
  lda EXTMEM_START+CODEHDR_NAME,X ; Filename starts at $0D offset from start of
  beq cmdprcXLS_name_loop_done  ; code. If char is 0, we're done
  jsr OSWRCH
  inx                             ; Increment for next char
  cmp #ZD_MAX_FN_LEN              ; Have we already printed a filename's worth?
  beq cmdprcXLS_name_loop_done  ; If so, we've gone too far
  jmp cmdprcXLS_name_loop       ; Otherwise, get another char
.cmdprcXLS_data_label
  LOAD_MSG xls_data_label
  jsr OSWRMSG
  jmp cmdprcXLS_name_loop_done
.cmdprcXLS_overlay_label
  LOAD_MSG xls_overlay_label
  jsr OSWRMSG
.cmdprcXLS_name_loop_done
  lda #CHR_LINEEND                ; Print a linefeed at the end of this entry
  jsr OSWRCH
  iny                             ; Increment to next bank
  cpy #16
  beq cmdprcXLS_done
  jmp cmdprcXLS_loop

.cmdprcXLS_done
  LED_OFF LED_FILE_ACT
  lda EXTMEM_BANK                 ; Restore the currently selected bank
  sta EXTMEM_SLOT_SEL
  jmp cmdprc_success

\ ------------------------------------------------------------------------------
\ --- CMD: XLOAD  :  LOAD EXECUTABLE CODE INTO EXTENDED RAM
\ ------------------------------------------------------------------------------
\ Usage: XLOAD <filename> <memory_bank>
\ Wrapper to xload_file.
\ This is for loading program code into extended memory. The given filename
\ should not have an extension (.BIN will be added by ZolaDOS).
\ The memory_bank must be in the range 0-15. The code will check that the
\ selected bank is writeable (ie, that it has not been switched to ROM).
.cmdprcXLOAD
  lda #ZD_OPCODE_LOAD
  jsr xload_file
  lda FUNC_ERR
  beq cmdprcXLOAD_success
  jmp cmdprc_fail
.cmdprcXLOAD_success
  jmp cmdprc_success

\ ------------------------------------------------------------------------------
\ --- CMD: XOPEN  :  RUN PROGRAM IN CURRENT EXTENDED MEMORY BANK
\ ------------------------------------------------------------------------------
\ Usage: XOPEN <filename> <bank>
\ Wrapper to xload_file.
\ Open a file and loads its contents into <bank>. Similar to XLOAD, except
\ that no extension is automatically added by ZolaDOS. Use for loading data
\ files into extended memory.
.cmdprcXOPEN
  lda #ZD_OPCODE_DLOAD
  jsr xload_file
  lda FUNC_ERR
  beq cmdprcXLOAD_success
  jmp cmdprc_fail


\ ON ENTRY: A should contain the relevant ZolaDOS opcode
.xload_file
  pha                        ; Keep opcode safe for now
  jsr read_filename          ; Read filename from STDIN_BUF, put in STR_BUF
  lda FUNC_ERR
  bne xload_file_done
  jsr extmem_readset_bank    ; Read memory bank number. Bank will be selected.
  lda FUNC_ERR
  bne xload_file_done
  jsr extmem_ram_chk         ; Check that the selected bank is available
  lda FUNC_ERR
  bne xload_file_done
  jmp xload_file_loadfile
.xload_file_bank_chk_err
  lda #ERR_EXTMEM_WR
  sta FUNC_ERR
  jmp xload_file_done
.xload_file_loadfile         ; Here's where we actually load the file
  LED_ON LED_FILE_ACT
  LOAD_MSG loading_msg
  jsr OSWRMSG
  jsr OSLCDMSG
  lda #<EXTMEM_START         ; This is where we're going to load the code
  sta FILE_ADDR
  lda #>EXTMEM_START
  sta FILE_ADDR+1
  pla                        ; Get the opcode back
  jsr OSZDLOAD               ; Run LOAD routine
  lda FUNC_ERR
  bne xload_file_done
  LOAD_MSG file_act_complete_msg
  jsr OSWRMSG
  jsr OSLCDMSG
  lda EXTMEM_BANK
  sta EXTMEM_SLOT_SEL        ; Select bank by writing to this addr
.xload_file_done
  LED_OFF LED_FILE_ACT
  rts

\ ------------------------------------------------------------------------------
\ --- CMD: XRUN  :  RUN PROGRAM IN CURRENT EXTENDED MEMORY BANK
\ ------------------------------------------------------------------------------
\ Usage: XRUN
\ Performs a jump to EXTMEM_START. First checks for a 'P' code - indicating that
\ an executable program is loaded in the currently selected bank.
.cmdprcXRUN
  stz STDIN_BUF                         ; Zero out input buffer
  stz STDIN_IDX                         ; and its index pointer
  stz PRG_EXIT_CODE                     ; Reset Program Exit Code
  LED_OFF LED_BUSY
  lda EXTMEM_START + CODEHDR_TYPE
  cmp #TYPECODE_EXEC                    ; Is it an executable?
  bne cmdprcXRUN_err
  jmp EXTMEM_START
.cmdprcXRUN_err
  lda #ERR_EXTMEM_EXEC
  sta FUNC_ERR
  jmp cmdprc_fail

\ ------------------------------------------------------------------------------
\ --- CMD: XSEL  :  SELECT EXTENDED MEMORY BANK
\ ------------------------------------------------------------------------------
\ Usage: XSEL <0-15>
.cmdprcXSEL
  jsr extmem_readset_bank               ; Set and select the bank
  lda FUNC_ERR
  beq cmdprcXSEL_success                ; If no error, we're done
  jmp cmdprc_fail                       ; Otherwise, do the error thing
.cmdprcXSEL_success
  stz STDOUT_IDX                        ; Zero-out STDOUT buffer
  stz STDOUT_BUF
  LOAD_MSG bank_select_msg              ; Let's announce which bank is selected
  jsr OSSOAPP
  lda EXTMEM_BANK
  jsr OSB2ISTR
  STR_BUF_TO_MSG_VEC
  jsr OSSOAPP
  jsr OSWRBUF
  jsr OSLCDWRBUF
  jmp cmdprc_success

\ --- DATA ----------------
.bank_select_msg
  equs "Bank selected: ",0
.xls_data_label
  equs "-- data --",0
.xls_overlay_label
  equs "-- overlay --",0
