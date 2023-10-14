\ CFG_SPI65.ASM

SPI_DATA_REG = $BF00
SPI_STAT_REG = $BF01	              ; When reading
SPI_CTRL_REG = $BF01	              ; When writing
SPI_DEV_SEL  = $BF02	              ; Device select

SPI_DEV_SRAM = %11011111            ; Device select setting for SRAM
SPI_DEV_SD   = %10111111            ; Device select setting for SD
SPI_DEV_RTC  = %01111111            ; Device select setting for RTC
SPI_DEV_NONE = %11111111

SPI_TC_FLAG   = %10000000
SPU_BUSY_FLAG = %01000000

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

\ ***** MACROS *****

MACRO SPI_COMM_START
  lda SPI_DATA_REG                  ; To clear TC flag, if set
  lda SPI_CURR_DEV
  sta SPI_DEV_SEL
ENDMACRO

MACRO SPI_CHECK_PRESENT
  lda SYS_REG
  and #SYS_SPI                  ; A=0 if interface not present, non-0 otherwise
ENDMACRO
