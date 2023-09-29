; Page 7 config - SPI, RTC, SD

\\ *****************************************************************************
\\ *****   SPI
\\ *****************************************************************************
;                                                           ADDR   BYTES   TOTAL
SPI_CURR_DEV = $0700                                      ; 0700     1       1
SPI_BUF_32   = SPI_CURR_DEV + 1							              ; 0701    32      33

\\ *****************************************************************************
\\ *****   RTC
\\ *****************************************************************************
RTC_REG_MASK = SPI_BUF_32 + 32                            ; 0721     1      34
RTC_CLK_BUF  = RTC_REG_MASK + 1                           ; 0722     3      37
; Order of 3 bytes is: Secs:Mins:Hour
RTC_DAT_BUF  = RTC_CLK_BUF + 3                            ; 0725     4      41
; Order of 4 bytes is: Day:Mon:Year:DoW

\\ *****************************************************************************
\\ *****   SD
\\ *****************************************************************************
SD_CMD_PARAMS = RTC_DAT_BUF + 4							              ;          7
; The above is a buffer for passing parameters to a command. It encompasses the
; following aliases:
  SD_CMD_NUM     = SD_CMD_PARAMS   ; Command number                 - 1 byte
  SD_CMD_ARGS 	 = SD_CMD_NUM + 1  ; Command arguments buffer       - 4 bytes
  ; NB: 32-bit values stored in the SD_CMD_ARGS bytes are stored big-endian
  SD_CMD_CRC     = SD_CMD_ARGS + 4 ; CRC value                      - 1 byte
  SD_CMD_RESP_SZ = SD_CMD_CRC + 1  ; No. bytes expected in response - 1 byte

SD_RESP_BUF = SD_CMD_ARGS + 6      ; Resp. buffer = SD_RESP_BUF_SZ   5
