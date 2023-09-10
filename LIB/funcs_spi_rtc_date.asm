
\ ------------------------------------------------------------------------------
\ ---  RTC_DISPLAY_DATE
\ ------------------------------------------------------------------------------
\ Display current date.
\ rtc_read_date should be called immediately before this function to put the
\ current time into the buffer.
.rtc_display_date
  pha : phx
  ldx #2
.rtc_display_date_loop
  cpx #0
  bne rtc_display_date_get_next
  lda #'2'
  jsr OSWRCH
  lda #'0'
  jsr OSWRCH
.rtc_display_date_get_next
  lda RTC_CLK_BUF,X
  jsr OSB2ISTR
  dec FUNC_RESULT                   ; Will start as 1 if result is single digit
  bne rtc_display_date_prt          ; 0 if single digit
  lda #'0'
  jsr OSWRCH
.rtc_display_date_prt
  jsr OSWRSBUF
  cpx #0
  beq rtc_display_date_done
  lda #'/'
  jsr OSWRCH
  dex
  jmp rtc_display_date_loop
.rtc_display_date_done
  plx : pla
  rts

\ ------------------------------------------------------------------------------
\ ---  RTC_READ_DATE
\ ------------------------------------------------------------------------------
\ Reads the date and puts values into RTC_CLK_BUF
.rtc_read_date
  ; READ YEAR
  lda #RTC_YEAR_REG
  jsr rtc_read_reg    ; Read the register. Result in A
  ldx #RTC_YRT_MASK
  stx RTC_REG_MASK
  jsr rtc_convert_from_bcd ; Now the value is in A
  sta RTC_CLK_BUF + 2

  ; READ MONTH
  lda #RTC_MNTH_REG
  jsr rtc_read_reg    ; Read the register. Result in A
  ldx #RTC_MONT_MASK
  stx RTC_REG_MASK
  jsr rtc_convert_from_bcd ; Now the value is in A
  sta RTC_CLK_BUF + 1

  ; READ DAY
  lda #RTC_DATE_REG
  jsr rtc_read_reg    ; Read the register. Result in A
  ldx #RTC_DATT_MASK
  stx RTC_REG_MASK
  jsr rtc_convert_from_bcd ; Now the value is in A
  sta RTC_CLK_BUF
  rts

\ ------------------------------------------------------------------------------
\ ---  RTC_SET_DATE
\ ------------------------------------------------------------------------------
.rtc_set_date
  sei
  ; SET DATE
  lda RTC_CLK_BUF
  jsr rtc_convert_to_bcd
  tax                           ; Put into X for later
  lda #RTC_DATW_MASK            ; Load appropriate write mask into RTC_REG_MASK
  sta RTC_REG_MASK
  lda #RTC_DATE_REG             ; Load A with value of register
  jsr rtc_write_reg_with_mask


  ; SET MONTH
  lda RTC_CLK_BUF + 1
  jsr rtc_convert_to_bcd
  tax                           ; Put into X for later
  lda #RTC_MONW_MASK            ; Load appropriate write mask into RTC_REG_MASK
  sta RTC_REG_MASK
  lda #RTC_MNTH_REG             ; Load A with value of register
  jsr rtc_write_reg_with_mask

  ; SET YEAR
  lda RTC_CLK_BUF + 2
  jsr rtc_convert_to_bcd
  tax                           ; Put into X for later
  lda #RTC_YRW_MASK             ; Load appropriate write mask into RTC_REG_MASK
  sta RTC_REG_MASK
  lda #RTC_YEAR_REG             ; Load A with value of register
  jsr rtc_write_reg_with_mask

  cli
  rts
