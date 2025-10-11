\ Functions to use the 256-byte SRAM built into the DS3234

\ ------------------------------------------------------------------------------
\ ---  RTC_READ_SRAM
\ ------------------------------------------------------------------------------
\ ON ENTRY: - A - Address of memory location
\ ON EXIT : - A - contains value at that address
\ NB: Immediately following a call to this function, subsequent calls to
\ rtc_read_reg with A set to #RTC_RAMD_REG will read sequential bytes of data.
.rtc_read_sram
  tax
  lda #RTC_RAMA_REG     ; Select the SRAM Address register
  jsr rtc_write_reg
  lda #RTC_RAMD_REG
  jsr rtc_read_reg
  rts

\ ------------------------------------------------------------------------------
\ ---  RTC_WRITE_SRAM
\ ------------------------------------------------------------------------------
\ ON ENTRY: - A - Address of memory location
\			      - X - Value to write
.rtc_write_sram
  phx                   ; Save the value for later
  tax                   ; Put address value into X
  lda #RTC_RAMA_REG     ; Select the SRAM Address register
  jsr rtc_write_reg
  plx                   ; Get back the value to write
  lda #RTC_RAMD_REG     ; Select the SRAM Data register
  jsr rtc_write_reg
  rts
