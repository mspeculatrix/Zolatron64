
\ ------------------------------------------------------------------------------
\ ---  RTC_DISPLAY_TIME
\ ------------------------------------------------------------------------------
\ Display current time.
\ rtc_read_time should be called immediately before this function to put the
\ current time into the buffer.
.rtc_display_time
  pha : phx
  ldx #2
.rtc_display_time_loop
  lda RTC_CLK_BUF,X
  jsr OSB2ISTR
  dec FUNC_RESULT                   ; Will start as 1 if result is single digit
  bne rtc_display_time_prt          ; 0 if single digit
  lda #'0'
  jsr OSWRCH
.rtc_display_time_prt
  jsr OSWRSBUF
  cpx #0
  beq rtc_display_time_done
  lda #':'
  jsr OSWRCH
  dex
  jmp rtc_display_time_loop
.rtc_display_time_done
  plx : pla
  rts

\ ------------------------------------------------------------------------------
\ ---  RTC_READ_TIME
\ ------------------------------------------------------------------------------
\ Reads the time and puts values into RTC_CLK_BUF
.rtc_read_time

  ; READ HOUR
  lda #RTC_HOUR_REG
  jsr rtc_read_reg    ; Read the register. Result in A
  ldx #RTC_HRT_MASK
  stx RTC_REG_MASK
  jsr rtc_convert_from_bcd ; Now the value is in A
  sta RTC_CLK_BUF + 2

  ; READ MINUTES
  lda #RTC_MINS_REG
  jsr rtc_read_reg    ; Read the register. Result in A
  ldx #RTC_MINT_MASK
  stx RTC_REG_MASK
  jsr rtc_convert_from_bcd ; Now the value is in A
  sta RTC_CLK_BUF + 1

  ; READ SECONDS
  lda #RTC_SECS_REG
  jsr rtc_read_reg    ; Read the register. Result in A
  ldx #RTC_SECT_MASK
  stx RTC_REG_MASK
  jsr rtc_convert_from_bcd ; Now the value is in A
  sta RTC_CLK_BUF

  rts


\ ------------------------------------------------------------------------------
\ ---  RTC_SET_TIME
\ ------------------------------------------------------------------------------
\ ON ENTRY: - Time values in RTC_CLK_BUF:
\               HRS  in RTC_CLK_BUF + 2
\               MINS in RTC_CLK_BUF + 1
\               SECS in RTC_CLK_BUF
\ ON EXIT :
\ A - ?     X - ?     Y - ?
.rtc_set_time
  sei
  ; SET SECONDS
  lda RTC_CLK_BUF
  jsr rtc_convert_to_bcd
  tax                           ; Put into X for later
  lda #RTC_SECW_MASK            ; Load appropriate write mask into RTC_REG_MASK
  sta RTC_REG_MASK
  lda #RTC_SECS_REG             ; Load A with number of register
  jsr rtc_write_reg_with_mask


  ; SET MINUTES
  lda RTC_CLK_BUF + 1
  jsr rtc_convert_to_bcd
  tax                           ; Put into X for later
  lda #RTC_MINW_MASK            ; Load appropriate write mask into RTC_REG_MASK
  sta RTC_REG_MASK
  lda #RTC_MINS_REG             ; Load A with number of register
  jsr rtc_write_reg_with_mask

  ; SET HOURS
  lda RTC_CLK_BUF + 2
  jsr rtc_convert_to_bcd
  tax                           ; Put into X for later
  lda #RTC_HRW_MASK             ; Load appropriate write mask into RTC_REG_MASK
  sta RTC_REG_MASK
  lda #RTC_HOUR_REG             ; Load A with number of register
  jsr rtc_write_reg_with_mask

  cli
  rts
