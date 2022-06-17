\ ---  FL_CLR_TABLE

.fl_clr_table

\ ------------------------------------------------------------------------------
\ ---  FL_LOAD   :   LOAD FLASH MEMORY
\ ------------------------------------------------------------------------------
\ ON ENTRY: - Memory bank must have been set in FLASH_BANK
\           - STR_BUF must contain filename
\ *** SHOULD THIS BE AN OS CALL ??? ***
.fl_load
  lda #<FLASHMEM_LOC                    ; This is where we're loading the data
  sta FILE_ADDR
  lda #>$FLASHMEM_LOC
  sta FILE_ADDR
  jsr OSZDLOAD                          ; Load
  lda FUNC_ERR                          ; Check for error
  beq fl_load_success                   ; If no error, skip...
  LED_ON LED_ERR
  jsr os_print_error
  jmp fl_load_end
.fl_load_success
  LOAD_MSG load_complete_msg
  jsr OSLCDMSG  
.fl_load_end
  rts
  