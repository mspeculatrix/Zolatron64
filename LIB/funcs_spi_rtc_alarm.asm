\ ------------------------------------------------------------------------------
\ ---  RTC_DISPLAY_ALARM
\ ------------------------------------------------------------------------------
\ Display current time.
\ rtc_read_alarm should be called immediately before this function to put the
\ current time into the buffer.
.rtc_display_alarm
  pha : phx
  ldx #2
.rtc_display_alarm_loop
  lda RTC_CLK_BUF,X
  jsr OSB2ISTR
  dec FUNC_RESULT                   ; Will start as 1 if result is single digit
  bne rtc_display_alarm_prt          ; 0 if single digit
  lda #'0'
  jsr OSWRCH
.rtc_display_alarm_prt
  jsr OSWRSBUF
  cpx #0
  beq rtc_display_alarm_done
  lda #':'
  jsr OSWRCH
  dex
  jmp rtc_display_alarm_loop
.rtc_display_alarm_done
  plx : pla
  rts

\ ------------------------------------------------------------------------------
\ ---  RTC_READ_ALARM
\ ------------------------------------------------------------------------------
\ Reads the alarm time and puts values into RTC_CLK_BUF
.rtc_read_alarm
  ; READ HOUR
  lda #RTC_ALM1_HR
  jsr rtc_read_reg    ; Read the register. Result in A
  ldx #RTC_HRT_MASK
  stx RTC_REG_MASK
  jsr rtc_convert_from_bcd ; Now the value is in A
  sta RTC_CLK_BUF + 2
  ; READ MINUTES
  lda #RTC_ALM1_MIN
  jsr rtc_read_reg    ; Read the register. Result in A
  ldx #RTC_MINT_MASK
  stx RTC_REG_MASK
  jsr rtc_convert_from_bcd ; Now the value is in A
  sta RTC_CLK_BUF + 1
  ; READ SECONDS
  lda #RTC_ALM1_SEC
  jsr rtc_read_reg    ; Read the register. Result in A
  ldx #RTC_SECT_MASK
  stx RTC_REG_MASK
  jsr rtc_convert_from_bcd ; Now the value is in A
  sta RTC_CLK_BUF
  rts

\ NOT SURE THIS IS NEEDED as I've replicated this in the interrupt handling
\ routine in funcs_isr.asm. Could maybe move this to the init routine.
.rtc_clr_alarm_ints
  lda #RTC_STAT_REG
  jsr rtc_read_reg
  and #%11111100
  tax
  lda #RTC_STAT_REG
  jsr rtc_write_reg
  rts

.rtc_disable_alarm
  lda #RTC_CTRL_REG
  jsr rtc_read_reg            ; A now contains current reg value
  and #%11111110              ; Unset alarm bit
  tax
  lda #RTC_CTRL_REG
  jsr rtc_write_reg
  rts

.rtc_enable_alarm
  \ Enable alarm 1 in CTRL register
  lda #RTC_CTRL_REG
  jsr rtc_read_reg            ; A now contains current reg value
  ora #%00000001              ; Set alarm bit
  tax
  lda #RTC_CTRL_REG
  jsr rtc_write_reg
  rts

\ ------------------------------------------------------------------------------
\ ---  RTC_SET_ALARM
\ ------------------------------------------------------------------------------
\ ON ENTRY: Assumes Hour, Minute & Second of alarm are set in RTC_CLK_BUF + 2 and
\           RTC_CLK_BUF + 1 and RTC_CLK_BUF respectively.
.rtc_set_alarm
  jsr rtc_clr_alarm_ints      ; Just to be sure

  sei
  ; SET SECONDS
  lda RTC_CLK_BUF
  jsr rtc_convert_to_bcd
  tax                           ; Put into X for later
  lda #RTC_SECW_MASK            ; Load appropriate write mask into RTC_REG_MASK
  sta RTC_REG_MASK
  lda #RTC_ALM1_SEC             ; Load A with value of register
  jsr rtc_write_reg_with_mask

  ; SET MINUTES
  lda RTC_CLK_BUF + 1
  jsr rtc_convert_to_bcd
  tax                           ; Put into X for later
  lda #RTC_MINW_MASK            ; Load appropriate write mask into RTC_REG_MASK
  sta RTC_REG_MASK
  lda #RTC_ALM1_MIN             ; Load A with value of register
  jsr rtc_write_reg_with_mask

  ; SET HOURS
  lda RTC_CLK_BUF + 2
  jsr rtc_convert_to_bcd
  tax                           ; Put into X for later
  lda #RTC_HRW_MASK             ; Load appropriate write mask into RTC_REG_MASK
  sta RTC_REG_MASK
  lda #RTC_ALM1_HR             ; Load A with value of register
  jsr rtc_write_reg_with_mask

  jsr rtc_enable_alarm
  cli
  rts

.rtc_set_alarm_mode
  \ Set alarm mode
  lda #RTC_ALM1_DAT         ; This register needs bit 7 set to 1
  jsr rtc_read_reg          ; Read that register - value now in A
  ora #%10000000
  tax
  lda #RTC_ALM1_DAT
  jsr rtc_write_reg
  \ Remaining alarm registers need bit 7 set to 0
  ldy #2                    ; Loop counter
  lda #RTC_ALM1_HR          ; The number of the register to start with
  sta TMP_IDX               ; Keep here
.rtc_enable_alarm_loop
  lda TMP_IDX               ; Reload register number
  jsr rtc_read_reg          ; Read that register - value now in A
  and #%01111111            ; Set bit 7 to 0
  tax                       ; Put value in X
  lda TMP_IDX               ; Reload register number
  jsr rtc_write_reg         ; Store in register
  dec TMP_IDX               ; Decrease  the register number
  dey                       ; Decrement loop counter
  bpl rtc_enable_alarm_loop ; Go again if necessary
  rts
