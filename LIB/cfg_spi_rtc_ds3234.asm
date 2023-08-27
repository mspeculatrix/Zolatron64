RTC_SECS_REG = $00         \\ Seconds
RTC_MINS_REG = $01         \\ Minutes
RTC_HOUR_REG = $02
RTC_DAY_REG  = $03
RTC_DATE_REG = $04
RTC_MNTH_REG = $05          \\ Bit 7 = Century
RTC_YEAR_REG = $06

RTC_ALM1_SEC = $07
RTC_ALM1_MIN = $08
RTC_ALM1_HR  = $09
RTC_ALM1_DAT = $0A

RTC_ALM2_MIN = $0B
RTC_ALM2_HR  = $0C
RTC_ALM2_DAT = $0D

RTC_CTRL_REG = $0E          \\ Control
RTC_STAT_REG = $0F          \\ Control/Status
RTC_RAMA_REG = $18          \\ SRAM Address
RTC_RAMD_REG = $19          \\ SRAM Data

RTC_ALARM1   = $00
RTC_ALARM2   = $03          \\ Used as an offset in functions

ALARM_MODE_HM   = %100
ALARM_MODE_DHM  = %000

\\ Specific bits
RTC_CENTURY  = %10000000  \\ Reg: RTC_MNTH_REG.
RTC_OSC_OFF  = %10000000  \\ AND with RTC_STAT_REG  if result != 0, OSC is stopped
RTC_ALM1_RST = %11111110  \\ AND with RTC_STAT_REG & save back to reset alarm flag
RTC_ALM2_RST = %11111101  \\  "   "
RTC_ALM1_TST = %00000001  \\ AND with RTC_STAT_REG to test for alarm flag
RTC_ALM2_TST = %00000010  \\  "   "

\\ Masks
RTC_CLKU_MASK = %00001111 \\ for reading unit values for clock elements
RTC_SECT_MASK = %01110000 \\ for reading tens values for seconds
RTC_SECW_MASK = %10000000 \\ for writing
RTC_MINT_MASK = %01110000
RTC_MINW_MASK = %10000000 \\ for writing
RTC_HRT_MASK  = %00110000
RTC_HRW_MASK  = %11000000 \\ for writing

RTC_24HR_MASK = %10111111
RTC_DAY_MASK  = %00000111

RTC_DATT_MASK = %00110000
RTC_DATW_MASK = %00110000
RTC_MONT_MASK = %00010000
RTC_MONW_MASK = %11100000
RTC_YRT_MASK  = %11110000
RTC_YRW_MASK  = %00000000
RTC_DAYT_MASK = %00000000
RTC_DAYW_MASK = %11111000


RTC_CTRL_INIT = %00000100    \\ Initial state for CTRL register
RTC_STAT_INIT = %00000000    \\ Initial state for STAT register

\ CTRL register
\   Bit
\    7   oscillator on 0 = on
\    6   battery-backed square wave enable
\    5   force convert temperature
\    4   Rate select for square wave output
\    3     "    "
\    2   interrupt control 0=SQW output enabled  1=alarm interrupts enabled
\    1   alarm 2 enable interrupt
\    0   alarm 1 enable interrupt
\
\ STAT register
\   Bit
\    7   oscillator stop flag (read only)  1=stopped
\    6   battery-backed 32KHz output (default=1)
\    5   temp conversion rate
\    4     "     "
\    3   32KHz output enable (default = 1)
\    2   busy bit (read only) - 1 when chip is busy doing temp conversion
\    1   alarm flag 2
\    0   alarm flag 1


\\ ADDRESSES - Using page 7 for workspace
