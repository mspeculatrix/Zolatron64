\ --- PRINTER FUNCTIONS -- funcs_prt.asm ---------------------------------------

\ ******************************************************************************
\ ***  OS FUNCTIONS
\ ******************************************************************************

\ ------------------------------------------------------------------------------
\ ---  PRT_CHAR
\ ---  Implements: OSPRTCH
\ ------------------------------------------------------------------------------
\ Print a character. Blocking.
\ ON ENTRY: A contains ASCII char code
\ A - O (via subr)     X - n/a     Y - n/a
.prt_char
  LED_ON LED_BUSY
  pha
.prt_char_chk_busy
  lda PRT_CTRL_PORT
  and #PRT_BUSY
  bne prt_char_chk_busy
  pla
  sta PRT_DATA_PORT
  jsr prt_strobe
  LED_OFF LED_BUSY
  rts

\ ------------------------------------------------------------------------------
\ ---  PRT_CHECK_PRESENT
\ ------------------------------------------------------------------------------
\ Checks to see if a parallel port card is fitted by attempting to write to one
\ of the VIA's registers (the Port A data direction register) and read back the
\ values.
\ Should be run once during boot by the OS.
\ To test for the presence of the interface in user programs, do something like:
\      lda SYS_REG
\      and #SYS_PARALLEL
\      beq parallel_board_not_fitted
\ ON EXIT : - FUNC_ERR contains error code - 0 = no error
\           - Sets bit 2 in SYS_REG (SYS_PARALLEL)
\ A - P     X - P     Y - P
.prt_check_present
  pha : phx : phy
  stz FUNC_ERR
  lda PRLL_DATA_DDR                         ; Load initial value of DDR
  sta TMP_VAL                               ; and save for later
  ldx #0
.prt_check_present_loop
  lda prt_test_vals,X                       ; Load a test value
  beq prt_check_present_loop_done           ; If 0, we're finished
  sta TEST_VAL                              ; Store for later
  sta PRLL_DATA_DDR                         ; Store it in the register
  lda PRLL_DATA_DDR                         ; Read back the register
  cmp TEST_VAL                              ; Compare with the value we wrote
  bne prt_check_present_fail
  inx
  jmp prt_check_present_loop
.prt_check_present_fail
  lda #ERR_PRT_NOT_PRESENT
  sta FUNC_ERR
  lda SYS_REG
  and #SYS_PARALLEL_NO
  jmp prt_check_present_done
.prt_check_present_loop_done
  lda SYS_REG
  ora #SYS_PARALLEL
.prt_check_present_done
  sta SYS_REG
  ply : plx : pla
  rts

.prt_test_vals
  equs %01010101, %10101010, $FF, %11110000, %00001111, 0

\ ------------------------------------------------------------------------------
\ ---  PRT_CHECK_STATE
\ ---  Implemenents: OSPRTCHK
\ ------------------------------------------------------------------------------
\ ON EXIT : - FUNC_ERR contains error code - 0 = no error
\ A - O     X - n/a     Y - P
.prt_check_state
  phy
  stz FUNC_ERR
  lda PRT_CTRL_PORT               ; Get the state of the control port
  tay                             ; Keep a copy in Y
  and #PRT_SEL                    ; SELECT - High=online, Low=offline
  beq prt_chk_state_offline       ; If 0, we're offline.
  tya                             ; Get our original control port setting back
  and #PRT_PE                     ; Check for paper out
  bne prt_chk_state_paperout      ; Active high
  tya                             ; Get our original control port setting back
  and #PRT_ERR                    ; Check for error signal
  bne prt_chk_state_end           ; Active low
  lda #ERR_PRT_STATE_ERR
  sta FUNC_ERR
  jmp prt_chk_state_end
.prt_chk_state_offline
  lda #ERR_PRT_STATE_OL
  sta FUNC_ERR
  jmp prt_chk_state_end
.prt_chk_state_paperout
  lda #ERR_PRT_STATE_PE
  sta FUNC_ERR
.prt_chk_state_end
  ply
  rts

\ ------------------------------------------------------------------------------
\ ---  PRT_INIT
\ ---  Implements: OSPRTINIT
\ ------------------------------------------------------------------------------
\ Set up the VIA and initialise the printer by sending an /INIT pulse.
\ A - O     X - n/a     Y - n/a
.prt_init
  lda #PRT_CTRL_PT_DIR              ; Set pin directions for control port
  sta PRT_CTRL_DDR
  lda #$FF                          ; Set data port to output
  sta PRT_DATA_DDR
  stz PRT_DATA_PORT                 ; Set all data pins to 0, because...
  lda PRT_CTRL_PORT                 ; Set outputs high (OFF) to start
  ora #PRT_AF_OFF
  ora #PRT_STRB_OFF
  and #PRT_INIT_ON                  ; Now send /INIT signal
  sta PRT_CTRL_PORT
  pha
  PRT_PULSE_DELAY
  pla
  ora #PRT_INIT_OFF
  sta PRT_CTRL_PORT
  rts

\ ------------------------------------------------------------------------------
\ ---  PRT_MSG
\ ---  Implements: OSPRTMSG  - print string pointed to by MSG_VEC
\ ------------------------------------------------------------------------------
\ ON ENTRY: MSG_VEC pointer should point to a message to print
\ ON EXIT : - FUNC_RESULT will contain a result code
\           - MSG_VEC will point to an error msg if an error occurred
\ A - O     X - n/a     Y - O
.prt_msg
  ldy #PRT_STATE_CHKS         ; Number of attempts we'll make before giving up
.prt_msg_chk
  jsr prt_check_state
  lda FUNC_RESULT
  beq prt_msg_cont
  dey
  beq prt_msg_end             ; FUNC_RESULT still contains error code
  PRT_PULSE_DELAY
  jmp prt_msg_chk
.prt_msg_cont
  ldy #0
.prt_msg_loop
  jsr prt_check_state         ; Just a single check
  lda FUNC_RESULT
  bne prt_msg_end
  lda (MSG_VEC),Y
  beq prt_msg_ok
  jsr prt_char
  iny
  beq prt_msg_end             ; Y has rolled over so we've reached max chars
  jmp prt_msg_loop
.prt_msg_ok
  stz FUNC_RESULT
.prt_msg_end
  rts

\ ------------------------------------------------------------------------------
\ ---  PRT_STDOUT_BUF
\ ---  Implements: OSPRTBUF
\ ------------------------------------------------------------------------------
\ Prints STDOUT_BUF. Wrapper to OSPRTMSG
\ A - O     X - n/a     Y - n/a
.prt_stdout_buf
  lda #<STDOUT_BUF                              ; LSB of message
  sta MSG_VEC
  lda #>STDOUT_BUF                              ; MSB of message
  sta MSG_VEC+1
  jsr prt_msg
  rts

\ ------------------------------------------------------------------------------
\ --- PRT_STR_BUF
\ --- Implements: OSPRTSBUF
\ ------------------------------------------------------------------------------
\ Prints STR_BUF.  Wrapper to OSPRTMSG
\ A - O     X - n/a     Y - n/a
.prt_str_buf
  lda #<STR_BUF                              ; LSB of message
  sta MSG_VEC
  lda #>STR_BUF                              ; MSB of message
  sta MSG_VEC+1
  jsr prt_msg
  rts



\ ******************************************************************************
\ ***  INTERNAL FUNCTIONS
\ ******************************************************************************


\ ------------------------------------------------------------------------------
\ ---  PRT_CHECK_BUSY
\ ------------------------------------------------------------------------------
\ ON EXIT : - Carry clear if printer not busy
\           - Carry set if busy
\ A - O     X - n/a     Y - n/a
.prt_check_busy
  clc
  lda PRT_CTRL_PORT
  and #PRT_BUSY
  beq prt_check_busy_end
  sec
.prt_check_busy_end
  rts

\ ------------------------------------------------------------------------------
\ ---  PRT_STROBE
\ ------------------------------------------------------------------------------
\ Sends a strobe signal to the printer.
\ This uses a timer-based interval for the length of the strobe. Might be
\ interesting to try a version that instead waits for an /ACK from the printer.
.prt_strobe
\ A - O     X - n/a     Y - n/a
  lda PRT_CTRL_PORT
  and #PRT_STRB_ON
  sta PRT_CTRL_PORT
  lda #PRT_STROBE_DELAY
  sta LCDV_TIMER_INTVL
  stz LCDV_TIMER_INTVL + 1
  jsr OSDELAY
  lda PRT_CTRL_PORT
  ora #PRT_STRB_OFF
  sta PRT_CTRL_PORT
  rts


;.prt_wait_for_ack
;  stz FUNC_ERR
;.prt_wait_for_ack_loop
;  lda PRT_CTRL_PORT
;  and #PRT_ACK
;  bne prt_wait_for_ack_loop
;  rts
