\ ------------------------------------------------------------------------------
\ ---  RTC_INIT
\ ------------------------------------------------------------------------------
.rtc_init

  lda #RTC_HOUR_REG     ; Set 12/24 bit to ensure 24-hour operation
  jsr rtc_read_reg      ; Read hour reg - value now in A
  and #RTC_24HR_MASK    ; AND with this to ensure bit is unset
  tax                   ; Put in X for next operation
  lda #RTC_HOUR_REG     ; Specify Hour reg again
  jsr rtc_write_reg     ; And save

  lda #RTC_CTRL_REG     ; Set initial value for Control reg
  ldx #RTC_CTRL_INIT
  jsr rtc_write_reg
  lda #RTC_STAT_REG     ; Ste initial value for Status reg
  ldx #RTC_STAT_INIT
  jsr rtc_write_reg

  rts

\ **********  DISPLAY OPERATIONS ***********************************************

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
  dec FUNC_RESULT ; Will start as 1 if result is single digit
  bne rtc_display_time_prt ; 0 if single digit
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

.rtc_display_date
  rts


\ **********  TIME OPERATIONS **************************************************


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
  lda #RTC_SECS_REG             ; Load A with value of register
  jsr rtc_write_reg_with_mask


  ; SET MINUTES
  lda RTC_CLK_BUF + 1
  jsr rtc_convert_to_bcd
  tax                           ; Put into X for later
  lda #RTC_MINW_MASK            ; Load appropriate write mask into RTC_REG_MASK
  sta RTC_REG_MASK
  lda #RTC_MINS_REG             ; Load A with value of register
  jsr rtc_write_reg_with_mask

  ; SET HOURS
  lda RTC_CLK_BUF + 2
  jsr rtc_convert_to_bcd
  tax                           ; Put into X for later
  lda #RTC_HRW_MASK             ; Load appropriate write mask into RTC_REG_MASK
  sta RTC_REG_MASK
  lda #RTC_HOUR_REG             ; Load A with value of register
  jsr rtc_write_reg_with_mask

  cli
  rts


\ **********  REGISTER OPERATIONS **********************************************

\ ------------------------------------------------------------------------------
\ ---  RTC_READ_REG
\ ------------------------------------------------------------------------------
\ ON ENTRY: Register address should be in A
\ ON EXIT : A contains read value
\ A - O     X - n/a     Y - n/a
.rtc_read_reg
  SPI_COMM_START
  jsr spi_exchange_byte			; Selects the reg, don't care what's in A
  jsr spi_exchange_byte			; Sends dummy value, register value is in A
  SPI_COMM_END
  rts

\ ------------------------------------------------------------------------------
\ ---  RTC_WRITE_REG
\ ------------------------------------------------------------------------------
\ ON ENTRY: - Register address should be in A
\           - Value to be written should be in X
\ This does no masking of bits nor conversion to BCD
\ A - O     X - O     Y - n/a
.rtc_write_reg
  ora $80                   ; To select write version of register
  SPI_COMM_START
  jsr spi_exchange_byte			; Select the reg, don't care what comes back in A
  tax                       ; Put the value to write in A
  jsr spi_exchange_byte			; Send value
  SPI_COMM_END
  rts

\ ------------------------------------------------------------------------------
\ ---  RTC_WRITE_REG_WITH_MASK
\ ------------------------------------------------------------------------------
\ ON ENTRY: - Register address in A
\           - Value to be written in X
\           - Write mask in RTC_REG_MASK
\ A - O     X - O     Y - n/a
\ Example use:
\ assume a value of 53 to be written to minutes reg
\  lda #53
\  jsr rtc_convert_to_bcd        ; A now has 53 in BCD format
\  tax                           ; Put into X for later
\  lda #RTC_MINW_MASK            ; Load appropriate write mask into RTC_REG_MASK
\  sta RTC_REG_MASK
\  lda #RTC_MINS_REG             ; Load A with value of register
\  jsr rtc_write_reg_with_mask
.rtc_write_reg_with_mask
  ; First thing we need to do is get the current value of the register
  pha               ; Save reg address for later
  stx TMP_VAL       ; And store the value to be written
  jsr rtc_read_reg  ; Current reg value now in A
  and RTC_REG_MASK  ; Just keep the bits we need to preserve
  ora TMP_VAL       ; OR with the new value to be written
  tax               ; Put value back in X
  pla               ; Retrieve register address
  jsr rtc_write_reg
  rts

\ ------------------------------------------------------------------------------
\ ---  RTC_CONVERT_FROM_BCD
\ ------------------------------------------------------------------------------
\ Convert a register value to a value byte using the appropriate mask
\ ON ENTRY: - A contains register value
\           - RTC_REG_MASK contains tens mask value
\ ON EXIT : - A contains value
\ A - O     X - O     Y - n/a
\ Example use:
\   lda #RTC_MINS_REG
\   jsr rtc_read_reg    ; Read the register. Result in A
\   ldx #RTC_MINT_MASK
\   stx RTC_REG_MASK
\   jsr rtc_convert_from_bcd ; Now the value is in A
.rtc_convert_from_bcd
  pha                 ; Save original register value for later
  and RTC_REG_MASK    ; Get just the tens value
  clc
  ror A               ; Rotate tens bits into lower nibble
  ror A
  ror A
  ror A               ; A now has tens value
  ldx #10             ; Multiplier
  jsr uint8_mult      ; Multiply. Result is in FUNC_RES_L
  pla                 ; Get original value of reg back
  and #RTC_CLKU_MASK  ; Get just the units value
  clc
  adc FUNC_RES_L      ; Add in our tens value
  rts

\ ------------------------------------------------------------------------------
\ ---  RTC_CONVERT_TO_BCD
\ ------------------------------------------------------------------------------
\ Convert a one-byte value to the BCD values required by a register
\ ON ENTRY: - Byte value in A
\ ON EXIT : A contains value
\ A - O     X - O     Y - n/a
.rtc_convert_to_bcd
  ldx #10           ; Divide value by 10
  jsr uint8_div     ; FUNC_RESULT contains remainder, X contains quotient
  txa               ; We're going to put the quotient in the upper nibble
  asl A
  asl A
  asl A
  asl A             ; Now A has the tens value
  ora FUNC_RESULT   ; Add in the remainder. A now have BCD version.
  rts
