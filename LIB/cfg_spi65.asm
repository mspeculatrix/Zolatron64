SPI_DATA_REG = $BF00
SPI_STAT_REG = $BF01	; when reading
SPI_CTRL_REG = $BF01	; when writing
SPI_DEV_SEL  = $BF02	; device select

SPI_SRAM_DEV = 5
SPI_SD_DEV   = 6
SPI_RTC_DEV  = 7

\ ***** SERIAL RAM *****
SRAM_PG_SZ       = $20              ; Page size = 32 bytes
SRAM_CMD_READ  	 = $03              ; Read data from memory
SRAM_CMD_WRITE   = $02              ; Write data to memory
SRAM_CMD_EDIO    = $3B              ; Enter dual I/O mode
SRAM_CMD_RSTIO   = $FF              ; Reset dual I/O access
SRAM_CMD_RDMR    = $05              ; Read mode register
SRAM_CMD_WRMR    = $01              ; Write mode register

SRAM_BYTE_MODE = %00000000          ; Values to be written to mode reg
SRAM_PAGE_MODE = %10000000
SRAM_SEQU_MODE = %01000000

MACRO SPI_SELECT_RTC
  lda #SPI_RTC_DEV              ; Select the RTC
  sta SPI_DEV_SEL
ENDMACRO

MACRO SPI_SELECT_SD
  lda #SPI_SD_DEV              ; Select the RTC
  sta SPI_DEV_SEL
ENDMACRO

MACRO SPI_SELECT_SRAM
  lda #SPI_SRAM_DEV              ; Select the RTC
  sta SPI_DEV_SEL
ENDMACRO

MACRO SPI_COMM_START
  ldx SPI_DATA_REG    ; to clear TC flag, if set
  lda SPI_CURR_DEV
  sta SPI_DEV_SEL
ENDMACRO

MACRO SPI_COMM_END
  stz SPI_DEV_SEL
ENDMACRO

MACRO SPI_CHECK_PRESENT
  lda SYS_REG
  and #SYS_SPI          ; A will be 0 if interface not present, non-0 otherwise
ENDMACRO
