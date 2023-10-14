\ CFG_SPI_SD.ASM

SD_RESP_R1              = 1   ; Byte lengths of responses
SD_RESP_R2              = 2   ; First byte is R1, second is additional flags
SD_RESP_R3_R7           = 4   ; Response length not including first R1 byte

; COMMANDS - values relate to Command Index
SD_CMD0_GO_IDLE         = 0
SD_CMD0_ARG             = 0
SD_CMD0_CRC             = $94
SD_CMD8_SND_IF_COND     = 8
SD_CMD8_ARG             = $01AA
SD_CMD8_CRC             = $87
SD_CMD9_SND_CSD         = 9
SD_CMD10_SND_CID        = 10
SD_CMD12_STOP_TRANS     = 12
SD_CMD16_SET_BLKLEN     = 16
SD_CMD17_RD_SINGLE_BLK  = 17
SD_CMD18_RD_MULT_BLK    = 18
SD_CMD23_SET_BLK_COUNT  = 23
SD_CMD24_WR_BLK         = 24
SD_CMD25_WR_MULT_BLK    = 25
SD_CMD41_APPSND_OPCOND  = 41               ; This is an ACMD, precede with CMD55
SD_CMD41_ARG_HIGHW      = $4000
SD_CMD41_ARG_LOWW       = $0000
SD_CMD41_CRC            = $77
SD_CMD55_APP_CMD        = 55
SD_CMD55_ARG            = 0
SD_CMD55_CRC            = $65
SD_CMD58_READ_OCR       = 58
SD_CMD58_ARG            = 0
SD_CMD58_CRC            = $FD

SD_IDLE_MAX_ATTEMPTS  = 5         ; How many attempts to when using CMD0
SD_IDLE_DELAY         = 100       ; Pause between attempts
SD_INIT_MAX_ATTEMPTS  = 5
SD_INIT_DELAY         = 250

SD_MAX_RESP_ATTEMPTS  = 15
SD_RESP_DELAY         = 5   			; ms between response attempts
SD_RESP_BUF_SZ        = 5         ; No. bytes in response buffer
;SD_RESP_ATTEMPT_DELAY = 10

; These are the errors flagged in an R1 response (and the first byte of other
; responses).
SD_PARAM_ERROR      = %01000000  ; Flags returned in first response byte.
SD_ADDR_ERROR       = %00100000  ; AND response byte with these values to check
SD_ERASE_SEQ_ERROR  = %00010000  ; for individual errors
SD_CRC_ERROR        = %00001000
SD_ILLEGAL_CMD      = %00000100
SD_ERASE_RESET      = %00000010
SD_IN_IDLE          = %00000001

; These are my own error codes, starting at 129 in case I want to use the R1
; error codes above in some clever way.
SD_ERR_RESP_TO   = 129
SD_ERR_IDLE      = SD_ERR_RESP_TO + 1
SD_ERR_IFCOND    = SD_ERR_IDLE + 1
SD_ERR_OPCOND    = SD_ERR_IFCOND + 1

SD_POWERED_UP       = %10000000  ; These are to be compared with top byte of OCR
SD_HIGH_CAPACITY    = %01000000

SD_DATA_START 	    = $FE        ; Response indicating start of data transm.

FAT_REC_BYTES       = 4          ; How many bytes in a FAT record

MACRO SD_START_OP
  lda SPI_CURR_DEV              ; -- Comm Start --
  sta SPI_DEV_SEL               ; --  "     "   --
ENDMACRO

MACRO SD_STOP_OP
  lda #$FF                      ; Every operation should end with 8 clock cycles
  jsr OSSPIEXCH
  lda #SPI_DEV_NONE             ; -- Comm End --
  sta SPI_DEV_SEL               ; --  "    "  --
ENDMACRO


MACRO DELAY millisecs
  lda #<millisecs
  sta LCDV_TIMER_INTVL
  lda #>millisecs
  sta LCDV_TIMER_INTVL + 1
  jsr OSDELAY
ENDMACRO


;struct SDpartition {
;  uint8_t state = 0;              // from MBR
;  uint32_t firstSector = 0;       // from MBR
;  uint16_t sectorSize = 512;      // from Partition BR
;  uint8_t sectorsPerCluster = 8;  //   "     "       "
;  uint16_t reservedSectors = 32;  //   "     "       "
;  uint8_t fatCopies = 2;          //   "     "       "
;  uint32_t numSectors = 0;        //   "     "       "
;  uint32_t sectorsPerFAT = 0;     //   "     "       "
;  char volName[12] = {0};         //   "     "       "
;  uint32_t fatStartSect = 0;      // = firstSector + reservedSectors
;  uint32_t dataStartSect = 0;     // = fatStartSect + (2 * sectorsPerFAT)
;}

;struct SDfile {
;  char name[12] = {0};            // from Dir record
;  uint8_t attribute = 0;          //   "   "     "
;  uint32_t firstCluster = 0;      //   "   "     "
;  uint32_t size = 0;              //   "   "     "
;  uint16_t fatSector = 0;         // Calculated
;  uint16_t fatByteOffset = 0;     // Calculated
;  uint32_t firstSector = 0;       // Calculated
;}
