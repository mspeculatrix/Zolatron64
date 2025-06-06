\ FUNCS_RTC_CORE.ASM

\ ------------------------------------------------------------------------------
\ ---  RTC_READ_DATE
\ ---  Implements: OSRDDATE
\ ------------------------------------------------------------------------------
\ ON ENTRY:
\ ON EXIT :
\ A - O     X - O     Y - n/a
._OSRDDATE
.rtc_read_date
  jsr rtc_select
  lda FUNC_ERR
  bne rtc_read_date_done

  ; READ YEAR
  lda #RTC_YEAR_REG
  jsr rtc_read_reg    ; Read the register. Result in A
  ldx #RTC_YRT_MASK
  stx RTC_REG_MASK
  jsr rtc_convert_from_bcd ; Now the value is in A
  sta RTC_DAT_BUF + 2

  ; READ MONTH
  lda #RTC_MNTH_REG
  jsr rtc_read_reg    ; Read the register. Result in A
  ldx #RTC_MONT_MASK
  stx RTC_REG_MASK
  jsr rtc_convert_from_bcd ; Now the value is in A
  sta RTC_DAT_BUF + 1

  ; READ DATE
  lda #RTC_DATE_REG
  jsr rtc_read_reg    ; Read the register. Result in A
  ldx #RTC_DATT_MASK
  stx RTC_REG_MASK
  jsr rtc_convert_from_bcd ; Now the value is in A
  sta RTC_DAT_BUF

  ; READ DOW
  lda #RTC_DAY_REG
  jsr rtc_read_reg    ; Read the register. Result in A
  ; This register doesn't need a mask or converting from BCD
  sta RTC_DAT_BUF + 3
.rtc_read_date_done
  rts

\ ------------------------------------------------------------------------------
\ ---  RTC_READ_TIME
\ ---  Implements: OSRDTIME
\ ------------------------------------------------------------------------------
\ ON ENTRY:
\ ON EXIT :
\ A - ?     X - ?     Y - ?
._OSRDTIME
.rtc_read_time
  jsr rtc_select
  lda FUNC_ERR
  bne rtc_read_time_done
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
.rtc_read_time_done
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
\ ---  RTC_READ_REG
\ ------------------------------------------------------------------------------
\ ON ENTRY: - Register number should be in A
\ ON EXIT : - A contains read value
\ A - O     - X - O     Y - n/a
.rtc_read_reg
  pha                               ; Save register number for later
  lda SPI_CURR_DEV                  ; -- Comm Start
  sta SPI_DEV_SEL                   ; --  "     "
  pla                               ; Get register number back
  jsr OSSPIEXCH			                ; Selects the reg
  jsr OSSPIEXCH			                ; Register value returned in A
  ldx #SPI_DEV_NONE                 ; -- Comm End --
  stx SPI_DEV_SEL                   ; --  "    "  --
  rts

\ ------------------------------------------------------------------------------
\ ---  RTC_SELECT
\ ------------------------------------------------------------------------------
\ Select the device and SPI Mode.
\ Checks to see if SPI board fitted. If not, returns
.rtc_select
  stz FUNC_ERR                  ; Zero out error by default
  lda SYS_REG                   ; Load system register
  and #SYS_SPI                  ; Is SPI flag set?
  beq rtc_select_error          ; If not, this is an error
  lda #SPI_DEV_RTC              ; Select the RTC
  sta SPI_CURR_DEV
  lda #%00000011                ; Set SPI Mode 3 on 65SPI
  sta SPI_CTRL_REG
  jmp rtc_select_done
.rtc_select_error
  lda #ERR_SPI_NOT_PRESENT
  sta FUNC_ERR
.rtc_select_done
  rts
