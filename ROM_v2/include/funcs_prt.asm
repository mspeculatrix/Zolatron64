\ funcs_prt.asm

\ ------------------------------------------------------------------------------
\ ---  PRT_INIT
\ ---  Implements: OSPRTINIT
\ ------------------------------------------------------------------------------
\ Set up the VIA. Make this an OS call?
.prt_init 
  lda #PRT_CTRL_PT_DIR              ; Set pin directions
  sta PRT_CTRL_DDR
  lda #$FF                          ; Set data port to output
  sta PRT_DATA_DDR
  stz PRT_DATA_PORT
  lda PRT_CTRL_PORT                 ; Set outputs high to start
  ora PRT_AF_OFF
  ora PRT_STRB_OFF                     
  and PRT_INIT_ON
  sta PRT_CTRL_PORT
  pha
  PRT_PULSE_DELAY
  pla
  ora PRT_INIT_OFF
  sta PRT_CTRL_PORT
  rts

\ OS Calls to implement
\ OSPRTBUF  - print STDOUT_BUF

.prt_stdout_buf
  rts

\ ------------------------------------------------------------------------------
\ ---  PRT_CHAR
\ ---  Implements: OSPRTCH
\ ------------------------------------------------------------------------------
\ Print a character. Blocking.
\ ON ENTRY: A contains ASCII char code
.prt_char
  jsr prt_check_busy
  bcs prt_char
  sta PRT_DATA_PORT
  PRT_PULSE_STROBE
  rts


\ ------------------------------------------------------------------------------
\ ---  PRT_MSG
\ ---  Implements: OSPRTMSG  - print string pointed to by MSG_VEC
\ ------------------------------------------------------------------------------
\ ON ENTRY: MSG_VEC pointer should point to a message to print
\ ON EXIT : - FUNC_RESULT will contain a result code
\           - MSG_VEC will point to an error msg if an error occurred
.prt_msg
  jsr prt_check_state
  lda FUNC_RESULT
  bne prt_msg_end
  ldy #0
.prt_msg_loop
  lda (MSG_VEC),Y
  beq prt_msg_end
  jsr prt_char
  iny
  jmp prt_msg_loop
.prt_msg_end
  jsr prt_load_msg
  rts

\ ------------------------------------------------------------------------------
\ --- PRT_STR_BUF
\ --- Implements: OSPRTSBUF
\ ------------------------------------------------------------------------------
.prt_str_buf
  lda #<STR_BUF                              ; LSB of message
  sta MSG_VEC
  lda #>STR_BUF                              ; MSB of message
  sta MSG_VEC+1
  jsr prt_msg
  rts

\ ------------------------------------------------------------------------------
\ ---  PRT_CHECK_STATE
\ ------------------------------------------------------------------------------
\ ON EXIT : FUNC_RESULT contains error code - 0 = no error
.prt_check_state
  stz FUNC_RESULT
  lda PRT_CTRL_PORT
  and #PRT_SEL
  beq prt_chk_state_offline       ; Active high
  lda PRT_CTRL_PORT
  and #PRT_PE
  bne prt_chk_state_paperout      ; Active high
  lda PRT_CTRL_PORT
  and #PRT_ERR
  beq prt_chk_state_error         ; Active low
.prt_chk_state_offline
  lda #PRT_STATE_OFFLINE
  sta FUNC_RESULT
  jmp prt_chk_state_end
.prt_chk_state_paperout
  lda #PRT_STATE_PE
  sta FUNC_RESULT
  jmp prt_chk_state_end
.prt_chk_state_error
  lda #PRT_STATE_ERR
  sta FUNC_RESULT
.prt_chk_state_end
  rts

.prt_state_msg_ptrs
  equw prt_state_msg_ok
  equw prt_state_msg_offline
  equw prt_state_msg_pe
  equw prt_state_msg_err

.prt_state_msg_ok
  equs "OK",0
.prt_state_msg_offline
  equs "OFFLINE",0
.prt_state_msg_pe
  equs "PAPER OUT",0
.prt_state_msg_err
  equs "ERROR",0

\ ------------------------------------------------------------------------------
\ ---  PRT_LOAD_MSG
\ ------------------------------------------------------------------------------
\ Puts a message into the message vector
\ ON ENTRY: Assumes an error/result code in FUNC_RESULT
.prt_load_msg
  lda FUNC_RESULT
  asl A                           ; Multiply by 2 to get offset for table
  tax
  lda prt_state_msg_ptrs,X        ; Get LSB of relevant address from the table
  sta MSG_VEC                     ; and put in MSG_VEC
  lda prt_state_msg_ptrs+1,X      ; Get MSB
  sta MSG_VEC+1                   ; and put in MSG_VEC high byte
  rts

\ ------------------------------------------------------------------------------
\ ---  PRT_CHECK_BUSY
\ ------------------------------------------------------------------------------
\ ON EXIT : - Carry clear if printer not busy
\           - Carry set if busy
.prt_check_busy
  clc
  lda PRT_CTRL_PORT
  and #PRT_BUSY
  beq prt_check_ready_end
  sec
.prt_check_ready_end
  rts
